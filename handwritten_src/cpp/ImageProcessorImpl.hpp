#pragma once

#include "ImageProcessor.hpp"
#include "read-dicekey.hpp"

namespace dicekeys {
class ImageProcessorImpl : public ImageProcessor {
    std::shared_ptr<DiceKeyImageProcessor> reader;

public:
    ImageProcessorImpl();

    bool processRGBAImage(int32_t width, int32_t height, const std::vector<uint8_t> & bytes);

    std::vector<uint8_t> processRGBAImageAndRenderOverlay(int32_t width, int32_t height, const std::vector<uint8_t> & bytes);

    std::vector<uint8_t> processAndAugmentRGBAImage(int32_t width, int32_t height, const std::vector<uint8_t> & bytes);

    std::string readJson();

    bool isFinished();

    std::vector<uint8_t> getFaceImage(int32_t faceIndex, int32_t height, const std::vector<uint8_t> & bytes);
};
}
