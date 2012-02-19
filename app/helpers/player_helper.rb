module PlayerHelper

  def players_size(*conditions)
    return 0 if @user.nil?
    find_players(*conditions).size
  end

  def player_list(*conditions)
    return '' if @user.nil?
    players = find_players(*conditions)
    players.map {|p| p.firstname}.sort.to_sentence
  end

private
  def find_players(*conditions)
    return nil if @user.nil?
    Player.find_all_by_user(@user, *conditions)
  end

end