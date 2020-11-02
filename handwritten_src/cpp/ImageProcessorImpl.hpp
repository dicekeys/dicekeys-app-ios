#pragma once

#include "ImageProcessor.hpp"
#include "read-dicekey.hpp"

namespace dicekeys {
class ImageProcessorImpl : public ImageProcessor {
    std::shared_ptr<DiceKeyImageProcessor> reader;

public:
    ImageProcessorImpl();

    bool process(const std::vector<uint8_t> & image, int32_t width, int32_t height);

    std::vector<uint8_t> overlay(const std::vector<uint8_t> & image, int32_t width, int32_t height);

    std::vector<uint8_t> augmented(const std::vector<uint8_t> & image, int32_t width, int32_t height);

    std::string json();

    bool isFinished();

    std::vector<uint8_t> faceImage(int32_t faceIndex, int32_t height, const std::vector<uint8_t> & bytes);
};
}
