#include <iostream>

#include <api/create_peerconnection_factory.h>

int main() {
    auto googleSessionDescription = webrtc::CreateSessionDescription(
            webrtc::SdpType::kOffer, "sdp");
    std::cout << "Hello, World!" << std::endl;
    return 0;
}
