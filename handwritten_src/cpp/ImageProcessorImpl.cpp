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

bool ImageProcessorImpl::process(const std::vector<uint8_t> & image, int32_t width, int32_t height) {
    return reader->processRGBAImage(width, height, (const uint32_t *)image.data());
}

std::vector<uint8_t> ImageProcessorImpl::overlay(const std::vector<uint8_t> & image, int32_t width, int32_t height) {
    // Scan codes
    reader->processRGBAImage(width, height, (const uint32_t *)image.data());
    // Create empty collection
    std::vector<uint8_t> overlay(image.size());
    // Render overlay
    reader->renderAugmentationOverlay(width, height, (uint32_t *)overlay.data());
    return overlay;
}

std::vector<uint8_t> ImageProcessorImpl::augmented(const std::vector<uint8_t> & image, int32_t width, int32_t height) {
    // Scan codes
    reader->processRGBAImage(width, height, (const uint32_t *)image.data());
    // Render overlay over original image
    reader->augmentRGBAImage(width, height, (uint32_t *)image.data());
    return image;
}

std::string ImageProcessorImpl::json() {
    return reader->jsonDiceKeyRead();
}

bool ImageProcessorImpl::isFinished() {
    return reader->isFinished();
}

std::vector<uint8_t> ImageProcessorImpl::faceImage(int32_t faceIndex, int32_t height, const std::vector<uint8_t> & bytes) {
    return std::vector<uint8_t>();
}
}
