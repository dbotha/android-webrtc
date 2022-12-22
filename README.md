# Building

`docker build --progress=plain -t webrtc-android:0.0.1 .`

This will fail at the linking stage due to duplicate symbols:

`error: duplicate symbol: std::runtime_error::operator=(std::runtime_error const&)`, etc.