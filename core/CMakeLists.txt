add_library(player_core STATIC
    src/services/PlayerService.cpp
    src/services/LibraryService.cpp
    src/services/QueueService.cpp
)

target_include_directories(player_core PUBLIC
    include
)
