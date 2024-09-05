use starknet::ContractAddress;
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

use bytebeasts::models::GameId
use bytebeasts::models::GameStatus
use bytebeasts::models::Game
use bytebeasts::models::GamePlayer

#[dojo::interface]
trait IActions {
    fn create_initial_game_id(ref world: IWorldDispatcher);
    fn create_game(ref world: IWorldDispatcher) -> Game;
    fn join_game(ref world: IWorldDispatcher, game_id: u128, player_two_address: ContractAddress);
}

#[dojo::contract]
mod actions {
    use starknet::{ContractAddress, get_caller_address, SyscallResultTrait};
    use starknet::{get_tx_info, get_block_number};
    use bytebeasts::models::{GameId, GameStatus, Game, GamePlayer};

    use super::IActions;

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn create_initial_game_id(ref world: IWorldDispatcher) {
            let existing_game_id = get!(world, 1, (GameId));
            if (existing_game_id.game_id > 0) {
                panic!("error global game id already created");
            }
            let game_id: GameId = GameId { id: 1, game_id: 1 };
            set!(world, (game_id));
        }

        fn create_game(ref world: IWorldDispatcher) -> Game {
            let player_1_address = get_caller_address();
            let mut game_id: GameId = get!(world, 1, (GameId));
            let player_1 = GamePlayerTrait::new(game_id.game_id, player_1_address);
            let game: Game = GameTrait::new(game_id.game_id, player_1_address);
            game_id.game_id += 1;
            set!(world, (player_1, game, game_id));
            game
        }

        fn join_game(
            ref world: IWorldDispatcher, game_id: u128, player_2_address: ContractAddress
        ) {
            let mut game = get!(world, game_id, (Game));
            assert!(
                game.player_2 == core::num::traits::Zero::<ContractAddress>::zero(),
                "player_2 already set"
            );
            let player_2 = GamePlayerTrait::new(game.game_id, player_2_address);
            game.join_game(player_2);
            let player_2 = GamePlayerTrait::new(game.game_id, player_2_address);
            set!(world, (player_2, game));
        }

        fn is_game_finished(ref world: IWorldDispatcher, game_id: u128) -> bool {
            let mut game: Game = get!(world, game_id, (Game));
            let player_1: GamePlayer = get!(world, (game.player_1, game.game_id), (GamePlayer));
            let player_2: GamePlayer = get!(world, (game.player_2, game.game_id), (GamePlayer));
            game.is_game_finished(player_1, player_2)
        }
    }
}