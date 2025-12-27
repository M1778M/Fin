from conan import ConanFile
from conan.tools.cmake import CMake, CMakeToolchain, CMakeDeps, cmake_layout

class FinConan(ConanFile):
    name = "fin"
    version = "0.1"
    
    settings = "os", "arch", "compiler", "build_type"

    requires = (
        "llvm-core/19.1.7",
        "fmt/10.2.1",
        "gtest/1.14.0",
    )

    build_requires = ["ninja/1.11.1"]
    generators = "CMakeDeps", "CMakeToolchain"

    options = {
        "termcap/*:shared": [True, False],
        "termcap/*:with_ncurses": [True, False]
    }
    default_options = {
        "termcap/*:shared": False,
        "termcap/*:with_ncurses": False
    }

    def layout(self):
        cmake_layout(self)

    def generate(self):
        tc = CMakeToolchain(self)
        # Force C++20 for all packages
        tc.variables["CMAKE_CXX_STANDARD"] = "20"
        # Force C standard to 99 to fix old-style C errors
        tc.variables["CMAKE_C_STANDARD"] = "99"
        tc.generate()
        CMakeDeps(self).generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()
    def configure(self):
        if "termcap" in self.requires:
            self.options["termcap"].shared = False
            self.options["termcap"].with_ncurses = True  # or just remove termcap entirely
    def package(self):
        cmake = CMake(self)
        cmake.install()
