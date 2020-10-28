#pragma once

#include "App.hpp"

namespace dicekeys {
    class AppImpl : public App {
    public:
        AppImpl();
        std::string getHelloWorld();
    };
}
