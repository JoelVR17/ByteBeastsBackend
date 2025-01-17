#[cfg(test)]
mod tests {
    use core::{
        result::{Result, ResultTrait},
        array::ArrayTrait,
    };
    use bytebeasts::models::leaderboard::{Leaderboard, LeaderboardEntry, LeaderboardTrait};
    use alexandria_data_structures::array_ext::ArrayTraitExt;
    use alexandria_sorting::bubble_sort::bubble_sort_elements;

    fn create_mock_entry(player_id: u32, name: felt252, score: u32, wins: u32, losses: u32, highest_score: u32, is_active: bool) -> LeaderboardEntry {
        LeaderboardEntry {
            player_id: player_id,
            player_name: name,
            score: score,
            wins: wins,
            losses: losses,
            highest_score: highest_score,
            is_active: is_active,
        }
    }

    fn create_empty_leaderboard() -> Leaderboard {
        Leaderboard {
            leaderboard_id: 1,
            name: 'Global Leaderboard',
            description: 'Top players worldwide',
            entries: ArrayTrait::new(),
            last_updated: 0,
        }
    }

    #[test]
    fn test_add_single_entry() {
        let mut leaderboard = create_empty_leaderboard();
        let entry = create_mock_entry(1, 'Alice', 100, 10, 5, 100, true);
        let res = leaderboard.add_entry(entry);
        assert_eq!(res.is_ok(), true);
        assert_eq!(leaderboard.entries.len(), 1);
        assert_eq!(leaderboard.entries.at(0).player_name, @'Alice', "Wrong player name");
    
        let duplicate_res = leaderboard.add_entry(entry);
        assert_eq!(duplicate_res.is_err(), true, "Duplicate entry should return error");
    }

    #[test]
    fn test_add_multiple_entry() {
        let mut leaderboard = create_empty_leaderboard();
        let entry1 = create_mock_entry(12, 'Alice', 1100, 10, 5, 100, true);
        let entry2 = create_mock_entry(2, 'Bob', 200121, 20, 10, 200, true);
        let entry3 = create_mock_entry(34, 'Charlie', 1300, 30, 15, 300, true);
        let entry4 = create_mock_entry(9, 'David', 22400, 40, 20, 400, true);
        let entry5 = create_mock_entry(5, 'Eve', 500, 50, 25, 500, true);

        let _ = leaderboard.add_entry(entry4);
        let _ = leaderboard.add_entry(entry5);
        let entries = array![entry1, entry2, entry3, entry4, entry5];
        let not_added = leaderboard.add_batch(entries);
        assert_eq!(leaderboard.entries.len(), 5, "Wrong number of entries");
        assert_eq!(not_added.len(), 2, "Wrong number of not added entries");
        assert_eq!(leaderboard.entries.at(0).player_name, @'Bob', "Wrong first player name");
        assert_eq!(leaderboard.entries.at(4).player_name, @'Eve', "Wrong last player name");

        let duplicate_entries = array![entry1, entry2];
        let not_added_duplicates = leaderboard.add_batch(duplicate_entries);
        assert_eq!(not_added_duplicates.len(), 2, "Duplicate entries should not be added");
    }

    #[test]
    fn test_pop_front_n() {
        let mut leaderboard = create_empty_leaderboard();
        let entry1 = create_mock_entry(12, 'Alice', 1100, 10, 5, 100, true);
        let entry2 = create_mock_entry(2, 'Bob', 200121, 20, 10, 200, true);
        let entry3 = create_mock_entry(34, 'Charlie', 1300, 30, 15, 300, true);
        let _ = leaderboard.add_batch(array![entry1, entry2, entry3]);
        let popped_entries = leaderboard.pop_front_n(2);
        assert_eq!(popped_entries.len(), 2, "Wrong number of popped entries");
        assert_eq!(popped_entries.at(0).player_name, @'Bob', "Wrong first popped player name");
        assert_eq!(popped_entries.at(1).player_name, @'Charlie', "Wrong second popped player name");
        assert_eq!(leaderboard.entries.len(), 1, "Wrong number of remaining entries");
        assert_eq!(leaderboard.entries.at(0).player_name, @'Alice', "Wrong remaining player name");

        let mut empty_leaderboard = create_empty_leaderboard();
        let popped_entries_empty = empty_leaderboard.pop_front_n(5);
        assert_eq!(popped_entries_empty.len(), 0, "Popping from empty leaderboard should return empty array");
    }

    #[test]
    fn test_remove_entry() {
        let mut leaderboard = create_empty_leaderboard();
        let entry1 = create_mock_entry(12, 'Alice', 1100, 10, 5, 100, true);
        let entry2 = create_mock_entry(2, 'Bob', 200121, 20, 10, 200, true);
        let entry3 = create_mock_entry(34, 'Charlie', 1300, 30, 15, 300, true);
        let entry4 = create_mock_entry(9, 'David', 22400, 40, 20, 400, true);
        let entry5 = create_mock_entry(5, 'Eve', 500, 50, 25, 500, true);

        let entries = array![entry1, entry2, entry3, entry4, entry5];
        let _ = leaderboard.add_batch(entries);
        let res = leaderboard.remove_entry(entry3);
        assert_eq!(res.is_ok(), true);
        assert_eq!(leaderboard.entries.len(), 4, "Wrong number of entries");
        assert_eq!(leaderboard.entries.at(2).player_name, @'Alice', "Wrong player name");

        let non_existent_entry = create_mock_entry(99, 'NonExistent', 0, 0, 0, 0, false);
        let res_non_existent = leaderboard.remove_entry(non_existent_entry);
        assert_eq!(res_non_existent.is_err(), true, "Removing non-existent entry should return error");
    }

    #[test]
    fn test_get_index_by_player_id() {
        let mut leaderboard = create_empty_leaderboard();
        let entry1 = create_mock_entry(12, 'Alice', 1100, 10, 5, 100, true);
        let entry2 = create_mock_entry(2, 'Bob', 200121, 20, 10, 200, true);
        let entry3 = create_mock_entry(34, 'Charlie', 1300, 30, 15, 300, true);
        let entry4 = create_mock_entry(9, 'David', 22400, 40, 20, 400, true);
        let entry5 = create_mock_entry(5, 'Eve', 500, 50, 25, 500, true);

        let _ = leaderboard.add_batch(array![entry1, entry2, entry3, entry4, entry5]);
        let rank = leaderboard.get_index_by_player_id(34).unwrap();
        assert_eq!(rank, 2, "Wrong rank for Charlie");
        let rank = leaderboard.get_index_by_player_id(2).unwrap();
        assert_eq!(rank, 0, "Wrong rank for Bob");
        let rank = leaderboard.get_index_by_player_id(5).unwrap();
        assert_eq!(rank, 4, "Wrong rank for Eve");

        let non_existent_rank = leaderboard.get_index_by_player_id(99);
        assert_eq!(non_existent_rank.is_err(), true, "Getting index of non-existent player should return error");
    }

    #[test]
    fn test_update_entry() {
        let mut leaderboard = create_empty_leaderboard();
        let entry1 = create_mock_entry(12, 'Alice', 1100, 10, 5, 100, true);
        let entry2 = create_mock_entry(2, 'Bob', 200121, 20, 10, 200, true);
        let entry3 = create_mock_entry(34, 'Charlie', 1300, 30, 15, 300, true);
        let entry4 = create_mock_entry(9, 'David', 22400, 40, 20, 400, true);
        let entry5 = create_mock_entry(5, 'Eve', 500, 50, 25, 500, true);

        let _ = leaderboard.add_batch(array![entry1, entry2, entry3, entry4, entry5]);
        let new_score: u32 = 100;
        let new_wins: u32 = 31;
        let updated_entry = create_mock_entry(34, 'Charlie', new_score, new_wins, 15, 300, true);
        let res = leaderboard.update_entry(updated_entry);
        let rank = leaderboard.get_index_by_player_id(34).unwrap();
        assert_eq!(res.is_ok(), true);
        assert_eq!(rank, 4, "Wrong rank");
        assert_eq!(leaderboard.entries.len(), 5, "Wrong number of entries");
        assert_eq!(leaderboard.entries.at(rank).score, @new_score, "Wrong score");
        assert_eq!(leaderboard.entries.at(rank).wins, @new_wins, "Wrong wins");

        let non_existent_entry = create_mock_entry(99, 'NonExistent', 0, 0, 0, 0, false);
        let res_non_existent = leaderboard.update_entry(non_existent_entry);
        assert_eq!(res_non_existent.is_err(), true, "Updating non-existent entry should return error");
    }

    #[test]
    fn test_get_entries() {
        let mut leaderboard = create_empty_leaderboard();
        let entry1 = create_mock_entry(12, 'Alice', 1100, 10, 5, 100, true);
        let entry2 = create_mock_entry(2, 'Bob', 200121, 20, 10, 200, true);
        let _ = leaderboard.add_batch(array![entry1, entry2]);
        let entries = leaderboard.get_entries();
        assert_eq!(entries.len(), 2, "Wrong number of entries");
        assert_eq!(entries.at(0).player_name, @'Bob', "Wrong first player name");
        assert_eq!(entries.at(1).player_name, @'Alice', "Wrong second player name");

        let mut empty_leaderboard = create_empty_leaderboard();
        let entries_empty = empty_leaderboard.get_entries();
        assert_eq!(entries_empty.len(), 0, "Empty leaderboard should return empty array");
    }

    #[test]
    fn test_get_slice() {
        let mut leaderboard = create_empty_leaderboard();
        let entry1 = create_mock_entry(12, 'Alice', 1100, 10, 5, 100, true);
        let entry2 = create_mock_entry(2, 'Bob', 200121, 20, 10, 200, true);
        let entry3 = create_mock_entry(34, 'Charlie', 1300, 30, 15, 300, true);
        let entry4 = create_mock_entry(9, 'David', 22400, 40, 20, 400, true);
        let entry5 = create_mock_entry(5, 'Eve', 500, 50, 25, 500, true);

        let _ = leaderboard.add_batch(array![entry1, entry2, entry3, entry4, entry5]);
        let slice = leaderboard.get_slice(1, 4).unwrap();
        assert_eq!(slice.len(), 3, "Wrong number of entries in slice");
        assert_eq!(slice.at(0).player_name, @'David', "Wrong first player name in slice");
        assert_eq!(slice.at(2).player_name, @'Alice', "Wrong last player name in slice");

        let invalid_slice = leaderboard.get_slice(4, 1);
        assert_eq!(invalid_slice.is_err(), true, "Invalid slice range should return error");

        let out_of_bounds_slice = leaderboard.get_slice(1, 10);
        assert_eq!(out_of_bounds_slice.is_err(), true, "Out of bounds slice should return error");

        let mut empty_leaderboard = create_empty_leaderboard();
        let empty_slice = empty_leaderboard.get_slice(0, 1);
        assert_eq!(empty_slice.is_err(), true, "Empty leaderboard should return error");
    }

    #[test]
    fn test_calculate_score() {
        let mut leaderboard = create_empty_leaderboard();
        let wins: u32 = 10;
        let losses: u32 = 5;
        let highest_score: u32 = 100;
        let score = leaderboard.calculate_score(wins, highest_score, losses);
        let expected_score = wins * 100 + highest_score - losses * 70;
        assert_eq!(score, expected_score, "Wrong score calculation");
    }

    #[test]
    fn test_upgrade_entry_stats() {
        let mut leaderboard = create_empty_leaderboard();
        let entry5 = create_mock_entry(5, 'Eve', 500, 50, 25, 500, true);
        let entry3 = create_mock_entry(34, 'Charlie', 2250, 30, 15, 300, true);
        let entry1 = create_mock_entry(12, 'Alice', 2400, 10, 5, 100, true);
        let entry2 = create_mock_entry(2, 'Bob', 200121, 20, 10, 200, true);
        let entry4 = create_mock_entry(9, 'David', 22400, 40, 20, 400, true);

        let _ = leaderboard.add_batch(array![entry1, entry2, entry3, entry4, entry5]);
        let new_wins: u32 = 31;
        let new_losses: u32 = 10;
        let new_highest_score: u32 = 400;
        let total_wins: u32 = entry3.wins + new_wins;
        let total_losses: u32 = entry3.losses + new_losses;
        let res = leaderboard.upgrade_entry_stats(34, new_wins, new_losses, new_highest_score);
        let rank = leaderboard.get_index_by_player_id(34).unwrap();

        let negative_res = leaderboard.upgrade_entry_stats(31, new_wins, new_losses, new_highest_score);

        assert_eq!(res.is_ok(), true);
        assert_eq!(rank, 2, "Wrong rank after update");
        assert_eq!(leaderboard.entries.len(), 5, "Wrong number of entries");
        assert_eq!(leaderboard.entries.at(rank).wins, @total_wins, "Wrong wins");
        assert_eq!(leaderboard.entries.at(rank).losses, @total_losses, "Wrong losses");
        assert_eq!(leaderboard.entries.at(rank).highest_score, @new_highest_score, "Wrong highest score");
        assert_eq!(negative_res.is_err(), true, "Updating non-existent entry should return error");
    }
}