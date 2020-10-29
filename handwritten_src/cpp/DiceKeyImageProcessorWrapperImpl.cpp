#include "DiceKeyImageProcessorWrapperImpl.hpp"
#include <opencv2/imgcodecs.hpp>
#include <string>
#include "validate-faces-read.h"
#include "visualize-read-results.h"

namespace dicekeys {
std::shared_ptr<DiceKeyImageProcessorWrapper> DiceKeyImageProcessorWrapper::create() {
    return std::make_shared<DiceKeyImageProcessorWrapperImpl>();
}

DiceKeyImageProcessorWrapperImpl::DiceKeyImageProcessorWrapperImpl() {
    reader = std::make_shared<DiceKeyImageProcessor>();
}

bool DiceKeyImageProcessorWrapperImpl::processRGBAImage(int32_t width, int32_t height, const std::vector<uint8_t> & bytes) {
    auto ptr = (const uint32_t *)bytes.data();
    return reader->processRGBAImage(width, height, ptr);
}

std::vector<uint8_t> DiceKeyImageProcessorWrapperImpl::processRGBAImageAndRenderOverlay(int32_t width, int32_t height, const std::vector<uint8_t> & bytes) {
    // Scan codes
    reader->processRGBAImage(width, height, (const uint32_t *)bytes.data());
    // Create empty collection
    std::vector<uint8_t> overlay(bytes.size());
    // Render overlay
    reader->renderAugmentationOverlay(width, height, (uint32_t *)overlay.data());
    return overlay;
}

std::vector<uint8_t> DiceKeyImageProcessorWrapperImpl::processAndAugmentRGBAImage(int32_t width, int32_t height, const std::vector<uint8_t> & bytes) {
    // Scan codes
    reader->processRGBAImage(width, height, (const uint32_t *)bytes.data());
    // Create empty collection
    std::vector<uint8_t> augmented(bytes.size());
    // Render overlay
    reader->augmentRGBAImage(width, height, (uint32_t *)augmented.data());
    return augmented;
}

std::string DiceKeyImageProcessorWrapperImpl::readJson() {
    return reader->jsonDiceKeyRead();
}

bool DiceKeyImageProcessorWrapperImpl::isFinished() {
    return reader->isFinished();
}

std::vector<uint8_t> DiceKeyImageProcessorWrapperImpl::getFaceImage(int32_t faceIndex, int32_t height, const std::vector<uint8_t> & bytes) {
    return std::vector<uint8_t>();
}
}
