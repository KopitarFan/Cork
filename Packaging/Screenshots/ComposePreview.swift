import AppKit
import AVFoundation
import CoreGraphics
import Foundation
import ImageIO

@main
struct ComposePreview {
    private static let width = 1920
    private static let height = 1080
    private static let framesPerSecond = 30
    private static let secondsPerScene = 4.0
    private static let transitionDuration = 0.55

    static func main() async throws {
        guard CommandLine.arguments.count == 7 else {
            throw PreviewError.usage
        }

        let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
        let images = try CommandLine.arguments[2...6].map(loadImage)
        let videoOnlyURL = outputURL.deletingPathExtension().appendingPathExtension("video-only.mp4")
        let silenceWaveURL = outputURL.deletingPathExtension().appendingPathExtension("silence.wav")
        let silenceAACURL = outputURL.deletingPathExtension().appendingPathExtension("silence.m4a")

        for url in [outputURL, videoOnlyURL, silenceWaveURL, silenceAACURL] {
            try? FileManager.default.removeItem(at: url)
        }

        try writeVideo(images: images, to: videoOnlyURL)
        try writeSilence(to: silenceWaveURL, duration: secondsPerScene * Double(images.count))
        try convertToAAC(input: silenceWaveURL, output: silenceAACURL)
        try await combine(video: videoOnlyURL, audio: silenceAACURL, output: outputURL)

        try? FileManager.default.removeItem(at: videoOnlyURL)
        try? FileManager.default.removeItem(at: silenceWaveURL)
        try? FileManager.default.removeItem(at: silenceAACURL)
    }

    private static func writeVideo(images: [CGImage], to outputURL: URL) throws {
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let input = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 11_000_000,
                    AVVideoExpectedSourceFrameRateKey: framesPerSecond,
                    AVVideoMaxKeyFrameIntervalKey: 1,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
                ]
            ]
        )
        input.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height
            ]
        )

        guard writer.canAdd(input) else { throw PreviewError.couldNotCreateVideo }
        writer.add(input)
        guard writer.startWriting() else {
            throw writer.error ?? PreviewError.couldNotCreateVideo
        }
        writer.startSession(atSourceTime: .zero)

        let totalFrames = Int(secondsPerScene * Double(images.count) * Double(framesPerSecond))
        for frameIndex in 0..<totalFrames {
            while !input.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.002)
            }

            let elapsed = Double(frameIndex) / Double(framesPerSecond)
            let sceneIndex = min(Int(elapsed / secondsPerScene), images.count - 1)
            let sceneElapsed = elapsed - (Double(sceneIndex) * secondsPerScene)
            let transitionStart = secondsPerScene - transitionDuration
            let blend = sceneIndex < images.count - 1 && sceneElapsed > transitionStart
                ? (sceneElapsed - transitionStart) / transitionDuration
                : 0

            guard let buffer = makePixelBuffer(
                pool: adaptor.pixelBufferPool,
                current: images[sceneIndex],
                next: sceneIndex < images.count - 1 ? images[sceneIndex + 1] : nil,
                blend: blend
            ) else {
                throw PreviewError.couldNotCreateFrame
            }

            let time = CMTime(value: CMTimeValue(frameIndex), timescale: CMTimeScale(framesPerSecond))
            guard adaptor.append(buffer, withPresentationTime: time) else {
                throw writer.error ?? PreviewError.couldNotCreateFrame
            }
        }

        input.markAsFinished()
        let completion = DispatchSemaphore(value: 0)
        writer.finishWriting { completion.signal() }
        completion.wait()

        guard writer.status == .completed else {
            throw writer.error ?? PreviewError.couldNotCreateVideo
        }
    }

    private static func makePixelBuffer(
        pool: CVPixelBufferPool?,
        current: CGImage,
        next: CGImage?,
        blend: Double
    ) -> CVPixelBuffer? {
        guard let pool else { return nil }

        var buffer: CVPixelBuffer?
        guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer) == kCVReturnSuccess,
              let buffer
        else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            return nil
        }

        context.interpolationQuality = .high
        let destination = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(current, in: destination)

        if let next, blend > 0 {
            context.setAlpha(CGFloat(min(max(blend, 0), 1)))
            context.draw(next, in: destination)
        }

        return buffer
    }

    private static func writeSilence(to outputURL: URL, duration: Double) throws {
        let sampleRate: UInt32 = 48_000
        let channels: UInt16 = 2
        let bitsPerSample: UInt16 = 16
        let bytesPerSample = UInt32(bitsPerSample / 8)
        let frameCount = UInt32(duration * Double(sampleRate))
        let dataSize = frameCount * UInt32(channels) * bytesPerSample

        var wave = Data()
        wave.append(contentsOf: Array("RIFF".utf8))
        wave.appendLittleEndian(UInt32(36) + dataSize)
        wave.append(contentsOf: Array("WAVEfmt ".utf8))
        wave.appendLittleEndian(UInt32(16))
        wave.appendLittleEndian(UInt16(1))
        wave.appendLittleEndian(channels)
        wave.appendLittleEndian(sampleRate)
        wave.appendLittleEndian(sampleRate * UInt32(channels) * bytesPerSample)
        wave.appendLittleEndian(channels * UInt16(bytesPerSample))
        wave.appendLittleEndian(bitsPerSample)
        wave.append(contentsOf: Array("data".utf8))
        wave.appendLittleEndian(dataSize)
        wave.append(Data(count: Int(dataSize)))
        try wave.write(to: outputURL, options: .atomic)
    }

    private static func convertToAAC(input inputURL: URL, output outputURL: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/afconvert")
        process.arguments = [
            "-f", "m4af",
            "-d", "aac",
            "-b", "256000",
            "-s", "0",
            inputURL.path,
            outputURL.path
        ]
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw PreviewError.couldNotCreateAudio
        }
    }

    private static func combine(video videoURL: URL, audio audioURL: URL, output outputURL: URL) async throws {
        let videoAsset = AVURLAsset(url: videoURL)
        let audioAsset = AVURLAsset(url: audioURL)
        let composition = AVMutableComposition()
        let sourceVideoTracks = try await videoAsset.loadTracks(withMediaType: .video)
        let sourceAudioTracks = try await audioAsset.loadTracks(withMediaType: .audio)

        guard let sourceVideo = sourceVideoTracks.first,
              let sourceAudio = sourceAudioTracks.first,
              let videoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
              ),
              let audioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
              )
        else {
            throw PreviewError.couldNotCombineTracks
        }

        let duration = CMTime(seconds: secondsPerScene * 5, preferredTimescale: 600)
        try videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: sourceVideo, at: .zero)
        try audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: sourceAudio, at: .zero)

        guard let exporter = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetPassthrough
        ) else {
            throw PreviewError.couldNotCombineTracks
        }

        exporter.shouldOptimizeForNetworkUse = true
        try await exporter.export(to: outputURL, as: .mp4)
    }

    private static func loadImage(_ path: String) throws -> CGImage {
        let url = URL(fileURLWithPath: path)
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw PreviewError.couldNotReadImage(path)
        }

        let crop = CGRect(x: 0, y: 80, width: 2560, height: 1440)
        guard let cropped = image.cropping(to: crop) else {
            throw PreviewError.couldNotReadImage(path)
        }
        return cropped
    }
}

private extension Data {
    mutating func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { append(contentsOf: $0) }
    }
}

private enum PreviewError: LocalizedError {
    case usage
    case couldNotReadImage(String)
    case couldNotCreateFrame
    case couldNotCreateVideo
    case couldNotCreateAudio
    case couldNotCombineTracks

    var errorDescription: String? {
        switch self {
        case .usage:
            return "Usage: ComposePreview <output.mp4> <screenshot-1> ... <screenshot-5>"
        case .couldNotReadImage(let path):
            return "Could not read image at \(path)"
        case .couldNotCreateFrame:
            return "Could not render a preview frame"
        case .couldNotCreateVideo:
            return "Could not create the preview video"
        case .couldNotCreateAudio:
            return "Could not create the preview audio track"
        case .couldNotCombineTracks:
            return "Could not combine the preview video and audio tracks"
        }
    }
}
