cmake_minimum_required(VERSION 3.16)
project(clautolisp-gui-qt CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Widgets)

add_executable(clautolisp-gui-qt
  source/main.cpp
  source/sexp.cpp
  source/sexp.hpp
  source/dialog_window.cpp
  source/dialog_window.hpp
  source/wire.cpp
  source/wire.hpp
)

target_link_libraries(clautolisp-gui-qt PRIVATE
  Qt6::Core
  Qt6::Widgets
)

install(TARGETS clautolisp-gui-qt RUNTIME DESTINATION bin)
