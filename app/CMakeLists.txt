find_package(Qt6 REQUIRED COMPONENTS Widgets)

add_executable(Parakeet
    main.cpp
)

target_link_libraries(Parakeet PRIVATE
    player_core
    ui_adapter
    Qt6::Widgets
    ${SQLITE_LIBRARIES}
    ${TAGLIB_LIBRARIES}
)

install(TARGETS Parakeet
    RUNTIME DESTINATION bin
    BUNDLE DESTINATION .
)
