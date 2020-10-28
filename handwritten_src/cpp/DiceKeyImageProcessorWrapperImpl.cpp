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

std::string DiceKeyImageProcessorWrapperImpl::getHelloWorld() {
    std::string myString = "Hello DiceKeys World! ";

    time_t t = time(0);
    tm now=*localtime(&t);
    char tmdescr[200]={0};
    const char fmt[]="%r";
    if (strftime(tmdescr, sizeof(tmdescr)-1, fmt, &now)>0) {
        myString += tmdescr;
    }

    return myString;
}

bool DiceKeyImageProcessorWrapperImpl::processRGBAImage(int32_t width, int32_t height, const std::vector<uint8_t> & data) {
    return true;
}

bool DiceKeyImageProcessorWrapperImpl::processRGBAImageAndRenderOverlay(int32_t width, int32_t height, const std::vector<uint8_t> & data) {
    return true;
}

bool DiceKeyImageProcessorWrapperImpl::processAndAugmentRGBAImage(int32_t width, int32_t height, const std::vector<uint8_t> & data) {
    return true;
}

std::string DiceKeyImageProcessorWrapperImpl::readJson() {
    return "{}";
}

bool DiceKeyImageProcessorWrapperImpl::isFinished() {
    return true;
}

std::vector<uint8_t> DiceKeyImageProcessorWrapperImpl::getFaceImage(int32_t faceIndex, int32_t height, const std::vector<uint8_t> & data) {
    std::vector<uint8_t> result;
    return  result;
}
}
