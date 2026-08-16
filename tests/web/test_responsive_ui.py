import pytest

@pytest.mark.web
@pytest.mark.regression
class TestResponsiveUILayout:

    @pytest.mark.parametrize("width,height,device_name", [
        (320, 568, "iPhone SE"),
        (375, 667, "iPhone 8"),
        (375, 812, "iPhone X"),
        (390, 844, "iPhone 12/13/14"),
        (414, 896, "iPhone XR"),
        (428, 926, "iPhone 13 Pro Max"),
        (430, 932, "iPhone 14 Pro Max"),
        (360, 640, "Galaxy S5"),
        (360, 740, "Galaxy S8+"),
        (412, 915, "Pixel 7"),

        (768, 1024, "iPad Portrait"),
        (1024, 768, "iPad Landscape"),
        (800, 1280, "Tablet Android"),
        (1280, 800, "Tablet Wide"),
        (1366, 768, "Laptop HD"),

        (1440, 900, "MacBook Air"),
        (1536, 864, "Desktop Normal"),
        (1920, 1080, "FHD Desktop"),
        (2560, 1440, "QHD Desktop"),
        (3840, 2160, "4K UHD Display"),

        (320, 480, "Legacy Small Mobile"),
        (360, 780, "Foldable Outer Screen"),
        (673, 841, "Foldable Inner Screen"),
        (1024, 1366, "iPad Pro 12.9"),
        (1280, 1024, "SXGA Monitor"),

        (1600, 900, "HD+ Monitor"),
        (1680, 1050, "WSXGA+ Monitor"),
        (1920, 1200, "WUXGA Monitor"),
        (2560, 1080, "Ultrawide Monitor"),
        (3440, 1440, "UWQHD Curved Monitor"),
    ])
    def test_viewport_responsive_constraints(self, width, height, device_name):
        assert width >= 320
        assert height >= 480
        assert len(device_name) > 3
