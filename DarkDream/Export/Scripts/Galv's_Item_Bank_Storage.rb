#------------------------------------------------------------------------------#
#  Galv's Item/Bank Storage
#------------------------------------------------------------------------------#
#  For: RPGMAKER VX ACE
#  Version 1.7
#------------------------------------------------------------------------------#
#  2012-10-24 - Version 1.7 - Added multiple storages controlled with variable.
#                           - Changed name to Item/Bank Storage
#                           - changed alias naming for compatibility
#  2012-10-19 - Version 1.6 - Bug fixes
#  2012-10-19 - Version 1.5 - Fixed a max gold and withdrawing issue.
#                           - Added deposit all and withdraw all gold buttons.
#                           - party gold and item limits can now be set or use
#                           - the limit from a limit breaking script. (in theory)
#  2012-10-18 - Version 1.4 - Other small fixes
#  2012-10-18 - Version 1.3 - Added banking SE
#  2012-10-18 - Version 1.2 - Added gold storage and more script calls
#  2012-10-17 - Version 1.1 - Added script calls to control stored items.
#  2012-10-16 - Version 1.0 - Released
#------------------------------------------------------------------------------#
#  An item storage script. Allows the player to store as many items as he/she
#  requires in bank-like storage that can be accessed from anywhere.
#    
#  This script differs to my "Multiple Storage containers" script in that you
#  can have "banks" that store items and gold and can be accessed from anywhere.
#  It was designed to be used for one bank, but now has option to have more if
#  required.
#
#  My "Multiple Storage Containers" script stores only items within certain
#  events that can only be accessed by activating the particular event. This was
#  designed for location specific containers like chests, barrels, etc.
#
#  Here are some script calls that might be useful:
#------------------------------------------------------------------------------#
#
#  open_storage                         # Opens the item storage scene
#
#  store_add(type, id, amount)          # creates an item in storage
#  store_rem(type, id, amount)          # destroys an item in storage
#  store_count(type, id)                # returns amount of an item in storage
#
#  bank_add(amount)                     # adds amount of gold to bank
#  bank_rem(amount)                     # removes amount of gold from bank
#  bank_count                           # returns amount of gold in bank
#
#------------------------------------------------------------------------------#
#  EXPLAINATION:
#  type      this can be "weapon", "armor" or "item"
#  id        the ID of the item/armor/weapon
#  amount    the number of the item/armor/weapon/gold you want to remove
#
#  EXAMPLE OF USE:
#  store_add("weapon", 5, 20)
#  store_rem("item", 18, 99)
#  store_count("armor", 1)
#  bank_add(100)
#------------------------------------------------------------------------------#
#  More setup options further down.
#------------------------------------------------------------------------------#
 
$imported = {} if $imported.nil?
$imported["Item_Storage"] = true
 
module Storage
 
#------------------------------------------------------------------------------#
#  SCRIPT SETUP OPTIONS
#------------------------------------------------------------------------------#
 
  # BOX VARIABLE
  BOX_VAR = 14    # This is the variable ID to use to determine which box you are
                 # adding/removing items from. Set the variable to a box number
                 # right before any add/remove or opening storage script calls
                 # to tell them which box they will affect.
                 # Set to 0 if you only want 1 box storage in your game. You
                 # then don't have to change a variable before each script call.
 
 
  # COMMAND LIST VOCAB
  BANK = "Banque"
  STORE = "Stocker"
  REMOVE = "Retirer"
  CANCEL = "Retour"
 
  # OTHER VOCAB
  IN_STORAGE = "Dans le coffre"
  IN_INVENTORY = "Dans l'inventaire"
   
  GOLD_INVENTORY = "Equipe:"
  GOLD_BANKED = "Banque:"
  BANK_HELP = "Tenir BAS pour déposer. Tenir HAUT pour prendre." + "\n" +
              "W pour tout déposer. Q pour tout prendre."
   
 
  # OTHER OPTIONS
  SE = ["Equip2", 90, 100]        # Sound effect when storing/removing an item
  SE_BANK = ["Shop", 50, 150]     # Repeating sound effect when banking gold
                                  # ["SE Name", volume, pitch]
   
  STORE_PRICELESS = true          # Items worth 0 can be stored? true or false
  STORE_KEY = true                # Key items can be stored? true or false
 
   
  # PARTY LIMITS
  # NOTE: These limits set to 0 will use the default limits. In theory this will
  # be compatible with a limit breaker script by leaving them at 0. Or you can
  # set the party limits below to whatever you like.
   
  MAX_GOLD = 0                    # Max gold your PARTY can carry.
                                  # This will overwrite the default limit.
                                  # 0 means do not use this.
 
  MAX_ITEMS = 0                   # Max items your PARTY can carry. 
                                  # This will overwrite the default limit.
                                  # 0 means do not use this.
 
 
#------------------------------------------------------------------------------#
#  SCRIPT SETUP OPTIONS
#------------------------------------------------------------------------------#
 
end
 
 
class Scene_ItemBank < Scene_MenuBase
  def start
    super
    check_storage_exists
    create_help_window
    create_command_window
    create_dummy_window
    create_bank_window
    create_number_window
    create_status_window
    create_category_window
    create_take_window
    create_give_window
     
  end
   
  def check_storage_exists
    if $game_party.multi_storage[$game_variables[Storage::BOX_VAR]].nil?
      $game_party.multi_storage[$game_variables[Storage::BOX_VAR]] = {}
    end
  end
   
   
  #--------------------------------------------------------------------------
  # Create Windows
  #--------------------------------------------------------------------------
  def create_command_window
    @command_window = Window_BankCommand.new(Graphics.width)
    @command_window.viewport = @viewport
    @command_window.y = @help_window.height
    @command_window.set_handler(:bank,   method(:command_bank))
    @command_window.set_handler(:give,   method(:command_give))
    @command_window.set_handler(:take,    method(:command_take))
    @command_window.set_handler(:cancel, method(:return_scene))
  end
  def create_dummy_window
    wy = @command_window.y + @command_window.height
    wh = Graphics.height - wy
    @dummy_window = Window_Base.new(0, wy, Graphics.width, wh)
    @dummy_window.viewport = @viewport
  end
  def create_bank_window
    @bank_window = Window_Bank.new
    @bank_window.viewport = @viewport
    @bank_window.x = 0
    @bank_window.y = @help_window.height + @command_window.height
    @bank_window.hide
    @bank_window.set_handler(:ok,     method(:on_bank_cancel))
    @bank_window.set_handler(:cancel, method(:on_bank_cancel))
 
  end
   
  def create_number_window
    wy = @dummy_window.y
    wh = @dummy_window.height
    @number_window = Window_BankNumber.new(0, wy, wh)
    @number_window.viewport = @viewport
    @number_window.hide
    @number_window.set_handler(:ok,     method(:on_number_ok))
    @number_window.set_handler(:cancel, method(:on_number_cancel))
  end
  def create_status_window
    wx = @number_window.width
    wy = @dummy_window.y
    ww = Graphics.width - wx
    wh = @dummy_window.height
    @status_window = Window_BankItems.new(wx, wy, ww, wh)
    @status_window.viewport = @viewport
    @status_window.hide
  end
  def create_category_window
    @category_window = Window_ItemCategory.new
    @category_window.viewport = @viewport
    @category_window.help_window = @help_window
    @category_window.y = @dummy_window.y
    @category_window.hide.deactivate
    @category_window.set_handler(:ok,     method(:on_category_ok))
    @category_window.set_handler(:cancel, method(:on_category_cancel))
  end
  def create_give_window
    wy = @category_window.y + @category_window.height
    wh = Graphics.height - wy
    @give_window = Window_BankGive.new(0, wy, Graphics.width, wh)
    @give_window.viewport = @viewport
    @give_window.help_window = @help_window
    @give_window.hide
    @give_window.set_handler(:ok,     method(:on_give_ok))
    @give_window.set_handler(:cancel, method(:on_give_cancel))
    @category_window.item_window = @give_window
  end
  def create_take_window
    wy = @command_window.y + @command_window.height
    wh = Graphics.height - wy
    @take_window = Window_BankTake.new(0, wy, Graphics.width, wh)
    @take_window.viewport = @viewport
    @take_window.help_window = @help_window
    @take_window.hide
    @take_window.set_handler(:ok,     method(:on_take_ok))
    @take_window.set_handler(:cancel, method(:on_take_cancel))
    @category_window.item_window = @take_window
  end
 
  #--------------------------------------------------------------------------
  # * Activate Windows
  #--------------------------------------------------------------------------
  def activate_give_window
    @category_window.show
    @give_window.refresh
    @give_window.show.activate
    @status_window.hide
  end
  def activate_take_window
    @take_window.select(0)
    @take_window.refresh
    @take_window.show.activate
    @status_window.hide
  end
  def activate_bank_window
    @bank_window.refresh
    @bank_window.show.activate
    @help_window.set_text(Storage::BANK_HELP)
  end
 
   
  #--------------------------------------------------------------------------
  # HANDLER METHODS
  #--------------------------------------------------------------------------
  def on_category_ok
    activate_give_window
    @give_window.select(0) 
  end
  def on_category_cancel
    @command_window.activate
    @dummy_window.show
    @category_window.hide
    @give_window.hide
  end
  def command_give
    @dummy_window.hide
    @category_window.show.activate
    @give_window.show
    @give_window.unselect
    @give_window.refresh
  end
  def on_give_ok
    @item = @give_window.item
    if @item.nil?
      RPG::SE.stop
      Sound.play_buzzer
      @give_window.activate
      @give_window.refresh
      return
    else
      @status_window.item = @item
      @category_window.hide
      @give_window.hide
      @number_window.set(@item, max_give)
      @number_window.show.activate
      @status_window.show
    end
  end
  def on_give_cancel
    @give_window.unselect
    @category_window.activate
    @status_window.item = nil
    @help_window.clear
  end
  def command_take
    @dummy_window.hide
    activate_take_window
    @take_window.show
    @take_window.refresh
  end
  def command_bank
    #@dummy_window.hide
    activate_bank_window
    @bank_window.show
    @bank_window.refresh
  end
  def on_bank_cancel
    @command_window.activate
    @dummy_window.show
    @category_window.hide
    @bank_window.hide
    @help_window.clear
  end
  def on_take_ok
    @item = @take_window.item
    if @item.nil? || $game_party.multi_storage[$game_variables[Storage::BOX_VAR]].empty? || $game_party.item_number(@item) == $game_party.max_item_number(@item)
      RPG::SE.stop
      Sound.play_buzzer
      @take_window.activate
      @take_window.refresh
      return
    elsif
      @item = @take_window.item
      @status_window.item = @item
      @take_window.hide
      @number_window.set(@item, max_take)
      @number_window.show.activate
      @status_window.show
    end
  end
  def on_take_cancel
    @take_window.unselect
    @command_window.activate
    @dummy_window.show
    @take_window.hide
    @status_window.item = nil
    @help_window.clear
  end
  def on_number_ok
    RPG::SE.new(Storage::SE[0], Storage::SE[1], Storage::SE[2]).play
    case @command_window.current_symbol
    when :take
      do_take(@number_window.number)
    when :give
      do_give(@number_window.number)
    end
    end_number_input
    @status_window.refresh
  end
  def on_number_cancel
    Sound.play_cancel
    end_number_input
  end
  def end_number_input
    @number_window.hide
    case @command_window.current_symbol
    when :take
      activate_take_window
    when :give
      activate_give_window
    end
  end  
   
  #--------------------------------------------------------------------------
  # * Giving and taking methods
  #--------------------------------------------------------------------------
  def max_take
    if $game_party.multi_storage[$game_variables[Storage::BOX_VAR]][@item] > $game_party.max_item_number(@item) - $game_party.item_number(@item)
      $game_party.max_item_number(@item) - $game_party.item_number(@item)
    else
      $game_party.multi_storage[$game_variables[Storage::BOX_VAR]][@item]
    end
  end
  def max_give
    $game_party.item_number(@item)
  end
  def do_give(number)
    $game_party.lose_item(@item, number)
    if $game_party.multi_storage[$game_variables[Storage::BOX_VAR]][@item].nil?
      $game_party.multi_storage[$game_variables[Storage::BOX_VAR]][@item] = number
    else
      $game_party.multi_storage[$game_variables[Storage::BOX_VAR]][@item] += number
    end
  end
  def do_take(number)
    return if @item.nil?
    $game_party.gain_item(@item, number)
    $game_party.multi_storage[$game_variables[Storage::BOX_VAR]][@item] -= number
    $game_party.multi_storage[$game_variables[Storage::BOX_VAR]].delete(@item) if $game_party.multi_storage[$game_variables[Storage::BOX_VAR]][@item] <= 0
    if $game_party.multi_storage[$game_variables[Storage::BOX_VAR]].empty?
      @take_window.activate
    end
  end
   
end # Scene_ItemBank < Scene_MenuBase
 
 
#------------------------------------------------------------------------------#
#  Window Stored Items
#------------------------------------------------------------------------------#
 
class Window_StoreList_Bank < Window_Selectable
  def initialize(x, y, width, height)
    super
    @category = :none
    @data = []
  end
  def category=(category)
    return if @category == category
    @category = category
    refresh
    self.oy = 0
  end
  def col_max
    return 2
  end
  def item_max
    @data ? @data.size : 1
  end
  def item
    @data && index >= 0 ? @data[index] : nil
  end
  def current_item_enabled?
    enable?(@data[index])
  end
  def include?(item)
    case @category
    when :item
      item.is_a?(RPG::Item) && !item.key_item?
    when :weapon
      item.is_a?(RPG::Weapon)
    when :armor
      item.is_a?(RPG::Armor)
    when :key_item
      item.is_a?(RPG::Item) && item.key_item?
    else
      false
    end
  end
  def enable?(item)
    $game_party.multi_storage[$game_variables[Storage::BOX_VAR]].has_key?(item)
  end
  def make_item_list
    @data = $game_party.multi_storage[$game_variables[Storage::BOX_VAR]].keys {|item| include?(item) }
    @data.push(nil) if include?(nil)
  end
  def select_last
    select(@data.index($game_party.last_item.object) || 0)
  end
  def draw_item(index)
    item = @data[index]
    if item
      rect = item_rect(index)
      rect.width -= 4
      draw_item_name(item, rect.x, rect.y, enable?(item))
      draw_item_number(rect, item)
    end
  end
  def draw_item_number(rect, item)
    draw_text(rect, sprintf(":%2d", $game_party.multi_storage[$game_variables[Storage::BOX_VAR]][item]), 2)
  end
  def update_help
    @help_window.set_item(item)
  end
  def refresh
    make_item_list
    create_contents
    draw_all_items
  end
end # Window_StoreList_Bank < Window_Selectable
 
 
#------------------------------------------------------------------------------#
#  Window Stored Item amount
#------------------------------------------------------------------------------#
 
class Window_BankNumber < Window_Selectable
  attr_reader :number
  def initialize(x, y, height)
    super(x, y, window_width, height)
    @item = nil
    @max = 1
    @number = 1
  end
  def window_width
    return 304
  end
  def set(item, max)
    @item = item
    @max = max
    @number = 1
    refresh
  end
  def refresh
    contents.clear
    draw_item_name(@item, 0, item_y)
    draw_number
  end
  def draw_number
    change_color(normal_color)
    draw_text(cursor_x - 28, item_y, 22, line_height, "×")
    draw_text(cursor_x, item_y, cursor_width - 4, line_height, @number, 2)
  end
  def item_y
    contents_height / 2 - line_height * 3 / 2
  end
  def cursor_width
    figures * 10 + 12
  end
  def cursor_x
    contents_width - cursor_width - 4
  end
  def figures
    return 2
  end
  def update
    super
    if active
      last_number = @number
      update_number
      if @number != last_number
        Sound.play_cursor
        refresh
      end
    end
  end
  def update_number
    change_number(1)   if Input.repeat?(:RIGHT)
    change_number(-1)  if Input.repeat?(:LEFT)
    change_number(10)  if Input.repeat?(:UP)
    change_number(-10) if Input.repeat?(:DOWN)
  end
  def change_number(amount)
    @number = [[@number + amount, @max].min, 1].max
  end
  def update_cursor
    cursor_rect.set(cursor_x, item_y, cursor_width, line_height)
  end
   
end # Window_BankNumber < Window_Selectable
 
 
#------------------------------------------------------------------------------#
#  Window Store Item Status
#------------------------------------------------------------------------------#
 
class Window_BankItems < Window_Base
  def initialize(x, y, width, height)
    super(x, y, width, height)
    @item = nil
    @page_index = 0
    refresh
  end
  def refresh
    contents.clear
    draw_possession(4, 0)
    draw_stored(4, line_height)
    draw_equip_info(4, line_height * 2) if @item.is_a?(RPG::EquipItem)
  end
  def item=(item)
    @item = item
    refresh
  end
  def draw_possession(x, y)
    rect = Rect.new(x, y, contents.width - 4 - x, line_height)
    change_color(system_color)
    draw_text(rect, Storage::IN_INVENTORY)
    change_color(normal_color)
    draw_text(rect, $game_party.item_number(@item), 2)
  end
  def draw_stored(x, y)
    rect = Rect.new(x, y, contents.width - 4 - x, line_height)
    change_color(system_color)
    draw_text(rect, Storage::IN_STORAGE)
    change_color(normal_color)
    stored_amount = $game_party.multi_storage[$game_variables[Storage::BOX_VAR]][@item]
    stored_amount = 0 if stored_amount.nil?
    draw_text(rect, stored_amount, 2)
  end
  def draw_equip_info(x, y)
    status_members.each_with_index do |actor, i|
      draw_actor_equip_info(x, y + line_height * (i * 2.4), actor)
    end
  end
  def status_members
    $game_party.members[@page_index * page_size, page_size]
  end
  def page_size
    return 4
  end
  def page_max
    ($game_party.members.size + page_size - 1) / page_size
  end
  def draw_actor_equip_info(x, y, actor)
    enabled = actor.equippable?(@item)
    change_color(normal_color, enabled)
    draw_text(x, y, 112, line_height, actor.name)
    item1 = current_equipped_item(actor, @item.etype_id)
    draw_actor_param_change(x, y, actor, item1) if enabled
    draw_item_name(item1, x, y + line_height, enabled)
  end
  def draw_actor_param_change(x, y, actor, item1)
    rect = Rect.new(x, y, contents.width - 4 - x, line_height)
    change = @item.params[param_id] - (item1 ? item1.params[param_id] : 0)
    change_color(param_change_color(change))
    draw_text(rect, sprintf("%+d", change), 2)
  end
  def param_id
    @item.is_a?(RPG::Weapon) ? 2 : 3
  end
  def current_equipped_item(actor, etype_id)
    list = []
    actor.equip_slots.each_with_index do |slot_etype_id, i|
      list.push(actor.equips[i]) if slot_etype_id == etype_id
    end
    list.min_by {|item| item ? item.params[param_id] : 0 }
  end
  def update
    super
    update_page
  end
  def update_page
    if visible && Input.trigger?(:A) && page_max > 1
      @page_index = (@page_index + 1) % page_max
      refresh
    end
  end
   
end # Window_BankItems < Window_Base
 
 
#------------------------------------------------------------------------------#
#  Window Give Item
#------------------------------------------------------------------------------#
 
class Window_BankGive < Window_ItemList
  def initialize(x, y, width, height)
    super(x, y, width, height)
  end
  def current_item_enabled?
    enable?(@data[index])
  end
  def enable?(item)
    if item.is_a?(RPG::Item) 
      return false if item.key_item? && !Storage::STORE_KEY
    end
    if Storage::STORE_PRICELESS
      true
    else
      item && item.price > 0
    end
  end
end
 
 
#------------------------------------------------------------------------------#
#  Window Take Item
#------------------------------------------------------------------------------#
 
class Window_BankTake < Window_StoreList_Bank
  def initialize(x, y, width, height)
    super(x, y, width, height)
  end
  def current_item_enabled?
    enable?(@data[index])
  end
  def enable?(item)
    $game_party.multi_storage[$game_variables[Storage::BOX_VAR]][item] != 0 && $game_party.item_number(item) < $game_party.max_item_number(@item)
  end
end
 
 
#------------------------------------------------------------------------------#
#  Window Command
#------------------------------------------------------------------------------#
 
class Window_BankCommand < Window_HorzCommand
  def initialize(window_width)
    @window_width = window_width
    super(0, 0)
  end
  def window_width
    @window_width
  end
  def col_max
    return 4
  end
  def make_command_list
    add_command(Storage::BANK, :bank)
    add_command(Storage::STORE,    :give)
    add_command(Storage::REMOVE,   :take)
    add_command(Storage::CANCEL, :cancel)
  end
end
 
 
#------------------------------------------------------------------------------#
#  Window Bank
#------------------------------------------------------------------------------#
 
class Window_Bank < Window_Selectable
  def initialize
    super(0, 0, window_width, fitting_height(2))
    refresh
    @deposit_rate = 1
    @withdraw_rate = 1
  end
  def window_width
    return Graphics.width / 2
  end
  alias galv_bank_update update
  def update
    galv_bank_update
    gold_transfer if self.active
  end
  def gold_transfer
    if Input.repeat?(:DOWN) && $game_party.gold > 0 || Input.repeat?(:UP) && $game_party.gold_stored > 0 && $game_party.gold < $game_party.max_gold
        RPG::SE.new(Storage::SE_BANK[0], Storage::SE_BANK[1], Storage::SE_BANK[2]).play
    end
    if Input.press?(:DOWN)
      before = $game_party.gold
      $game_party.lose_gold(@deposit_rate)
      after = $game_party.gold
      $game_party.gold_stored += before - after
      @deposit_rate += 1
      refresh
    end
    if Input.trigger?(:R) && !Input.press?(:DOWN) && !Input.press?(:UP)
      return if $game_party.gold == 0
      before = $game_party.gold
      $game_party.lose_gold($game_party.gold)
      after = $game_party.gold
      $game_party.gold_stored += before - after
      refresh
      RPG::SE.new(Storage::SE_BANK[0], Storage::SE_BANK[1], Storage::SE_BANK[2]).play
    end
    if !Input.press?(:DOWN)
      @deposit_rate = 1
    end
    if Input.press?(:UP)
      return if $game_party.gold == $game_party.max_gold
      @withdraw_rate = $game_party.gold_stored if @withdraw_rate >= $game_party.gold_stored
      if @withdraw_rate + $game_party.gold > $game_party.max_gold
        @withdraw_rate = $game_party.max_gold - $game_party.gold
      end
      before = $game_party.gold_stored
      $game_party.gold_stored -= @withdraw_rate
      after = $game_party.gold_stored
      $game_party.gain_gold(before - after)
      if $game_party.gold_stored == 0
        return refresh
      end
      @withdraw_rate += 1
      refresh
    end
     
    if Input.trigger?(:L) && !Input.press?(:DOWN) && !Input.press?(:UP)
      take_all_gold = $game_party.gold_stored
      return if $game_party.gold == $game_party.max_gold || $game_party.gold_stored == 0
      if take_all_gold + $game_party.gold > $game_party.max_gold
        take_all_gold = $game_party.max_gold - $game_party.gold
      end
      before = $game_party.gold_stored
      $game_party.gold_stored -= take_all_gold
      after = $game_party.gold_stored
      $game_party.gain_gold(before - after)
      refresh
      RPG::SE.new(Storage::SE_BANK[0], Storage::SE_BANK[1], Storage::SE_BANK[2]).play
    end
    if !Input.press?(:UP)
      @withdraw_rate = 1
    end
  end
  def refresh
    contents.clear
    draw_gold_location(Storage::GOLD_INVENTORY, 0, 0, 250)
    draw_currency_value(value, currency_unit, 4, 0, contents.width - 8)
    draw_gold_location(Storage::GOLD_BANKED, 0, line_height * 1, 250)
    draw_currency_value(value_stored, currency_unit, 4, line_height * 1, contents.width - 8)
  end
  def draw_gold_location(vocab, x, y, width)
    change_color(system_color)
    draw_text(x, y, width, line_height, vocab)
  end
  def value
    $game_party.gold
  end
  def value_stored
    $game_party.gold_stored
  end
  def currency_unit
    Vocab::currency_unit
  end
  def open
    refresh
    super
  end
end
 
 
#------------------------------------------------------------------------------#
#  Game Party Additions
#------------------------------------------------------------------------------#
 
 
class Game_Party < Game_Unit
  attr_accessor :multi_storage
  attr_accessor :gold_stored
   
  alias galv_bank_init_all_items init_all_items
  def init_all_items
    galv_bank_init_all_items
    @storage = {}
    @stored_items = {}
    @stored_weapons = {}
    @stored_armors = {}
    @gold_stored = 0
  end
   
  def multi_storage
    @storage
  end
  def storage
    @stored_items
    @stored_weapons
    @stored_armors
  end
  def gold_stored
    @gold_stored
  end
 
  alias galv_bank_max_gold max_gold
  def max_gold
    return Storage::MAX_GOLD if Storage::MAX_GOLD > 0
    galv_bank_max_gold
  end
   
  alias galv_bank_max_item_number max_item_number
  def max_item_number(item)
    return Storage::MAX_ITEMS if Storage::MAX_ITEMS > 0
    return 99 if item.nil?
    galv_bank_max_item_number(item)
  end
   
end # Game_Party < Game_Unit
 
 
class Game_Interpreter
  def store_add(type, id, amount)
    if $game_party.multi_storage[$game_variables[Storage::BOX_VAR]].nil?
      $game_party.multi_storage[$game_variables[Storage::BOX_VAR]] = {}
    end
    case type
    when "weapon"
      @item = $data_weapons[id]
    when "item"
      @item = $data_items[id]
    when "armor"
      @item = $data_armors[id]
    end
    if $game_party.multi_storage[$game_variables[Storage::BOX_VAR]][@item].nil?
      $game_party.multi_storage[$game_variables[Storage::BOX_VAR]][@item] = amount
    else
      $game_party.multi_storage[$game_variables[Storage::BOX_VAR]][@item] += amount
    end
  end
  def store_rem(type, id, amount)
    if $game_party.multi_storage[$game_variables[Storage::BOX_VAR]].nil?
      $game_party.multi_storage[$game_variables[Storage::BOX_VAR]] = {}
    end
    case type
    when "weapon"
      @item = $data_weapons[id]
    when "item"
      @item = $data_items[id]
    when "armor"
      @item = $data_armors[id]
    end
    return if $game_party.multi_storage[$game_variables[Storage::BOX_VAR]][@item].nil?
    if $game_party.multi_storage[$game_variables[Storage::BOX_VAR]][@item] <= amount
      $game_party.multi_storage[$game_variables[Storage::BOX_VAR]].delete(@item)
    else
      $game_party.multi_storage[$game_variables[Storage::BOX_VAR]][@item] -= amount
    end
  end
  def store_count(type, id)
    if $game_party.multi_storage[$game_variables[Storage::BOX_VAR]].nil?
      $game_party.multi_storage[$game_variables[Storage::BOX_VAR]] = {}
    end
    case type
    when "weapon"
      @item = $data_weapons[id]
    when "item"
      @item = $data_items[id]
    when "armor"
      @item = $data_armors[id]
    end
    return 0 if $game_party.multi_storage[$game_variables[Storage::BOX_VAR]][@item].nil?
    $game_party.multi_storage[$game_variables[Storage::BOX_VAR]][@item]
  end
  def bank_add(amount)
    $game_party.gold_stored += amount
  end
  def bank_rem(amount)
    $game_party.gold_stored -= amount
    $game_party.gold_stored = 0 if $game_party.gold_stored < 0
  end
  def bank_count
    $game_party.gold_stored
  end
  def open_storage
    SceneManager.call(Scene_ItemBank)
  end
end