import cv2
import numpy as np

# Read image with alpha channel
img = cv2.imread('assets/icon/kratos_foreground1.png', cv2.IMREAD_UNCHANGED)
alpha = img[:, :, 3]

# Resize to something manageable like 200x200
h, w = alpha.shape
scale = 200 / max(h, w)
resized = cv2.resize(alpha, (int(w * scale), int(h * scale)))

# Threshold
_, thresh = cv2.threshold(resized, 127, 255, cv2.THRESH_BINARY)

# Find contours
contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

# Get the largest contour
contour = max(contours, key=cv2.contourArea)

# Simplify contour
epsilon = 0.005 * cv2.arcLength(contour, True)
approx = cv2.approxPolyDP(contour, epsilon, True)

print("Path _buildHelmetPath(double w, double h) {")
print("  final path = Path();")
print(f"  // Original bbox: {w}x{h}, approximated to {int(w*scale)}x{int(h*scale)}")
print("  final sx = w / 200.0;")
print("  final sy = h / 200.0;")

first = True
for point in approx:
    x, y = point[0]
    if first:
        print(f"  path.moveTo({x} * sx, {y} * sy);")
        first = False
    else:
        print(f"  path.lineTo({x} * sx, {y} * sy);")

print("  path.close();")
print("  return path;")
print("}")
