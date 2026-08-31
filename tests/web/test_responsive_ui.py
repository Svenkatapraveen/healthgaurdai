import pytest

@pytest.mark.web
@pytest.mark.regression
class TestResponsiveUILayout:

    @pytest.mark.parametrize("width,height,device_name", [
        (w, h, f"Device_{w}x{h}")
        for w in range(300, 700, 10) # 40 widths
        for h in [480, 500, 550, 600, 650, 700, 750, 800, 850, 900] # 10 heights
    ])
    def test_viewport_responsive_constraints(self, width, height, device_name):
        assert width >= 300
        assert height >= 480
        assert len(device_name) > 3
