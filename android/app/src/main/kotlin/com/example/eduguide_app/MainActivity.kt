package com.example.eduguide_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode

class MainActivity : FlutterActivity() {
	// Use a TextureView-backed renderer to avoid SurfaceView buffer contention
	// errors like BLASTBufferQueue acquireNextBuffer on some devices when
	// switching activities (e.g., Google Sign-In) or using platform views.
	override fun getRenderMode(): RenderMode = RenderMode.texture
}
