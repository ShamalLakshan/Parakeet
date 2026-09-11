add_executable(Parakeet
    main.cpp
)

target_link_libraries(Parakeet PRIVATE
    player_core
    ui_adapter
    ${SQLITE_LIBRARIES}
    ${TAGLIB_LIBRARIES}
)
