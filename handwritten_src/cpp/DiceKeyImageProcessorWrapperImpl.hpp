#pragma once

#include "DiceKeyImageProcessorWrapper.hpp"
#include "read-dicekey.hpp"

namespace dicekeys {
class DiceKeyImageProcessorWrapperImpl : public DiceKeyImageProcessorWrapper {
    std::shared_ptr<DiceKeyImageProcessor> reader;

public:
    DiceKeyImageProcessorWrapperImpl();

    bool processRGBAImage(int32_t width, int32_t height, const std::vector<uint8_t> & bytes);

    std::vector<uint8_t> processRGBAImageAndRenderOverlay(int32_t width, int32_t height, const std::vector<uint8_t> & bytes);

    std::vector<uint8_t> processAndAugmentRGBAImage(int32_t width, int32_t height, const std::vector<uint8_t> & bytes);

    std::string readJson();

    bool isFinished();

    std::vector<uint8_t> getFaceImage(int32_t faceIndex, int32_t height, const std::vector<uint8_t> & bytes);
};
}
