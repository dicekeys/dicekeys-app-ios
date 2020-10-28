#pragma once

#include "DiceKeyImageProcessorWrapper.hpp"

namespace dicekeys {
class DiceKeyImageProcessorWrapperImpl : public DiceKeyImageProcessorWrapper {

public:
    DiceKeyImageProcessorWrapperImpl();

    /** This method is used to test integration between native and shared code */
    std::string getHelloWorld();

    bool processRGBAImage(int32_t width, int32_t height, const std::vector<uint8_t> & data);

    bool processRGBAImageAndRenderOverlay(int32_t width, int32_t height, const std::vector<uint8_t> & data);

    bool processAndAugmentRGBAImage(int32_t width, int32_t height, const std::vector<uint8_t> & data);

    std::string readJson();

    bool isFinished();

    std::vector<uint8_t> getFaceImage(int32_t faceIndex, int32_t height, const std::vector<uint8_t> & data);
};
}
