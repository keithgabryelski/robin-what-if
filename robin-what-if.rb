require 'time'

PEOPLE = 1024
TARGET_TIER = 14

$ticks = 0
$top_tier = 0
$unroomed_members = []
$robin_rooms = []
$dead_rooms = []
$top_room_number = 0
$top_person_number = 0

class RobinMember
  attr_accessor :room_number, :waittime, :past_room_numbers, :person_number
  def initialize
    @room_number = nil
    @waittime = 0
    @past_room_numbers = []
    $top_person_number += 1
    @person_number = $top_person_number
  end
end

class RobinRoom
  MERGE_TIMES = [2,3,7,15]
  attr_accessor :room_number, :room_tier, :time_to_merge, :members

  def initialize(room_tier, members)
    $top_room_number += 1
    @room_number = $top_room_number
    @room_tier = room_tier
    if $top_tier < room_tier
      $top_tier = room_tier
    end
    @time_to_merge = MERGE_TIMES[room_tier-1] || 31
    @members = members
  end

  def dead
    @members.length > 0
  end
end

def tick
  $ticks += 1
  rooms_ready = 0
  members_waiting = 0
  $robin_rooms.each do |room|
    room.time_to_merge -= 1
    if room.time_to_merge <= 0
      rooms_ready += 1
    end
    room.members.each do |member|
      member.waittime += 1
      members_waiting += 1
    end
  end
end

def merge_room(room1, room2)
  room1.members.each do |member|
    member.past_room_numbers << room1.room_number
  end
  room2.members.each do |member|
    member.past_room_numbers << room2.room_number
  end
  new_room = RobinRoom.new(room1.room_tier+1, room1.members + room2.members)
  room1.members = []
  room2.members = []
  $dead_rooms += [room1, room2]
  $robin_rooms -= [room1, room2]
  $robin_rooms << new_room
  new_room.members do |member|
    member.room_number = new_room.room_number
  end
  half_minus_one = new_room.members.length/2 - 1
  members = new_room.members.slice!(0...half_minus_one)
  members.each do |member|
    member.past_room_numbers << new_room.room_number
    member.room_number = nil
  end
  $unroomed_members += members
end

def merge_rooms
  mergeables = {}
  $robin_rooms.each do |room|
    if room.time_to_merge <= 0
      mergeables[room.room_tier] ||= []
      mergeables[room.room_tier] << room
    end
  end
  room_sets = mergeables.values.select do |mergeable|
    mergeable.length > 1
  end

  rooms_merged = false
  if room_sets.length > 0
    # we can merge a room
    room_sets.each do |room_set|
      while room_set.length > 1
        room1 = room_set.shift
        room2 = room_set.shift
        merge_room(room1, room2)
        rooms_merged = true
      end
    end
  end
  return rooms_merged
end

def add_new_room_with_two_members
  members = $unroomed_members.slice!(0..1)
  if members.length != 2
    return
  end
=begin
  while (members.length < 2)
    members << RobinMember.new
  end
=end
  $robin_rooms << RobinRoom.new(1, members)
end

def get_members_into_rooms
  while ($unroomed_members.length > 1)
    add_new_room_with_two_members
  end
end

while ($unroomed_members.length < PEOPLE)
  $unroomed_members << RobinMember.new
end

get_members_into_rooms

while true
  break if $top_tier == TARGET_TIER
  tick
  if !merge_rooms
    get_members_into_rooms
  end
end

def wait_time(ticks)
  days = ticks / (60 * 24)
  hours = (ticks - (days * (60 * 24))) / 60
  minutes = (ticks - (days * (60 * 24))) % 60
  return "days: #{days}, hours #{hours}, minutes: #{minutes}"
end
puts "after: #{wait_time($ticks)}, top_tier: #{$top_tier}"
puts "there are #{$robin_rooms.length} room(s)"
$robin_rooms.each do |room|
  puts "room:#{room.room_number} room_tier:#{room.room_tier}, members: #{room.members.length}"
  puts "members:"
  room.members.each do |member|
    puts "  member:#{member.person_number}: waittime: #{wait_time(member.waittime)}, past_rooms: #{member.past_room_numbers.length}"
  end
end
