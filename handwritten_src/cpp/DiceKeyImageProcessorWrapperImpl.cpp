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

bool DiceKeyImageProcessorWrapperImpl::processRGBAImage(int32_t width, int32_t height, const std::vector<uint8_t> & data) {
    return reader->processRGBAImage(width, height, (const uint32_t *)data.data());
}

bool DiceKeyImageProcessorWrapperImpl::processRGBAImageAndRenderOverlay(int32_t width, int32_t height, const std::vector<uint8_t> & data) {
    return true;
}

bool DiceKeyImageProcessorWrapperImpl::processAndAugmentRGBAImage(int32_t width, int32_t height, const std::vector<uint8_t> & data) {
    return true;
}

std::string DiceKeyImageProcessorWrapperImpl::readJson() {
    return reader->jsonDiceKeyRead();
}

bool DiceKeyImageProcessorWrapperImpl::isFinished() {
    return true;
}

std::vector<uint8_t> DiceKeyImageProcessorWrapperImpl::getFaceImage(int32_t faceIndex, int32_t height, const std::vector<uint8_t> & data) {
    std::vector<uint8_t> result;
    return  result;
}
}
