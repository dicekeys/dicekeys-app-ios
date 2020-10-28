#pragma once

#include "DiceKeyImageProcessorWrapper.hpp"

namespace dicekeys {
class DiceKeyImageProcessorWrapperImpl : public DiceKeyImageProcessorWrapper {

public:
    DiceKeyImageProcessorWrapperImpl();
    std::string getHelloWorld();
};
}
