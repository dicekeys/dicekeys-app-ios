#include "ImageProcessorImpl.hpp"
#include <opencv2/imgcodecs.hpp>
#include <string>
#include "validate-faces-read.h"
#include "visualize-read-results.h"

namespace dicekeys {
std::shared_ptr<ImageProcessor> ImageProcessor::create() {
    return std::make_shared<ImageProcessorImpl>();
}

ImageProcessorImpl::ImageProcessorImpl() {
    reader = std::make_shared<DiceKeyImageProcessor>();
}

bool ImageProcessorImpl::processRGBAImage(int32_t width, int32_t height, const std::vector<uint8_t> & bytes) {
    return reader->processRGBAImage(width, height, (const uint32_t *)bytes.data());
}

std::vector<uint8_t> ImageProcessorImpl::processRGBAImageAndRenderOverlay(int32_t width, int32_t height, const std::vector<uint8_t> & bytes) {
    // Scan codes
    reader->processRGBAImage(width, height, (const uint32_t *)bytes.data());
    // Create empty collection
    std::vector<uint8_t> overlay(bytes.size());
    // Render overlay
    reader->renderAugmentationOverlay(width, height, (uint32_t *)overlay.data());
    return overlay;
}

std::vector<uint8_t> ImageProcessorImpl::processAndAugmentRGBAImage(int32_t width, int32_t height, const std::vector<uint8_t> & bytes) {
    // Scan codes
    reader->processRGBAImage(width, height, (const uint32_t *)bytes.data());
    // Render overlay over original image
    reader->augmentRGBAImage(width, height, (uint32_t *)bytes.data());
    return bytes;
}

std::string ImageProcessorImpl::readJson() {
    return reader->jsonDiceKeyRead();
}

bool ImageProcessorImpl::isFinished() {
    return reader->isFinished();
}

std::vector<uint8_t> ImageProcessorImpl::getFaceImage(int32_t faceIndex, int32_t height, const std::vector<uint8_t> & bytes) {
    return std::vector<uint8_t>();
}
}
