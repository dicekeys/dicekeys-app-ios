#include "DiceKeyImageProcessorWrapperImpl.hpp"
#include <string>

namespace dicekeys {
std::shared_ptr<DiceKeyImageProcessorWrapper> DiceKeyImageProcessorWrapper::create() {
    return std::make_shared<DiceKeyImageProcessorWrapperImpl>();
}

DiceKeyImageProcessorWrapperImpl::DiceKeyImageProcessorWrapperImpl() {

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
}
