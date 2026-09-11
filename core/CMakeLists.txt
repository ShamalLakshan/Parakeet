add_library(player_core STATIC
    src/services/PlayerService.cpp
    src/services/LibraryService.cpp
)

target_include_directories(player_core PUBLIC
    include
)
