include Test # temporary WiP name for raylib bindings


WHITE = Color.new(r: 255, g: 255, b: 255, a: 255)
BLACK = Color.new(r: 0, g: 0, b: 0, a: 255)

CardWidth = 80
CardHeight = (CardWidth * (4.0/3.0)).to_i

# By how many steps to subdivide
# more can be smoother but needs more time to process
SmoothenSteps = 3

ScreenWidth = 900
ScreenHeight = 650

# How far the border is from the edge of the screen
ScreenBorder = 60
ScreenBorderThickness = 5

# Visual game border
BorderRec = Rectangle.new(
  x: ScreenBorder - ScreenBorderThickness,
  y: ScreenBorder - ScreenBorderThickness,
  width: ScreenWidth - ((ScreenBorder - ScreenBorderThickness) * 2),
  height: ScreenHeight - ((ScreenBorder - ScreenBorderThickness) * 2),
)

# Card arena limits
MaxCardHeight = ScreenBorder  
MinCardHeight = ScreenHeight - ScreenBorder -  CardHeight
MaxCardWidth = ScreenBorder  
MinCardWidth = ScreenWidth - ScreenBorder -  CardWidth

init_window(width: ScreenWidth, height: ScreenHeight, title: "Card Example Thingie")
Test.target_fps = 60

DefaultOrigin = Vector2.new(x: 0, y: 0)

class Card
  Width = CardWidth
  Height = CardHeight

  # List of valid coordinates a card can spawn
  ValidSpawnRange = [(ScreenBorder..(ScreenWidth-Card::Width-ScreenBorder)).to_a, (ScreenBorder..(ScreenHeight-Card::Height-ScreenBorder)).to_a] 

  # Stores any new cards that are created
  Objects = [] 

  # Stores groups of cards that are overlapping
  Resolver = [] 

  attr_accessor :rec, :text, :color, :dragged, :momentum

  def initialize(rec: Rectangle.new(x: ValidSpawnRange[0].sample, y: ValidSpawnRange[1].sample, width: Card::Width, height: Card::Height),
                 text: "New Card",
                 color: WHITE)
    self.rec = rec
    self.text = text
    self.color = color
    self.dragged = false
    self.momentum = [0.0, 0.0]
    Card::Objects.push self
  end

  # class methods
  class << self
    attr_accessor :card_offset
    attr_writer :card_dragged

    def card_dragged
      @card_dragged ||= false
    end

    def resolve_drag
      # if click -> find if you are clicking one -> if so set it click
      if mouse_button_pressed?(0)
        Card::Objects.reverse_each do |card|
          if check_collision_point_rec(point: mouse_position, rec: card.rec)
            self.card_dragged = card
            card.dragged = true
            self.card_offset = [card.rec.x - mouse_x, card.rec.y - mouse_y]

            # Place card at end of array(to draw on top)
            Card::Objects.push Card::Objects.delete(card)
            break
          end
        end
        # if holding click -> check which one is being clicked -> drag it
      elsif mouse_button_down?(0) && self.card_dragged
        card_dragged.rec = Rectangle.new(
          x: (self.card_offset[0] + mouse_x).clamp(MaxCardWidth, MinCardWidth),
          y: (self.card_offset[1] + mouse_y).clamp(MaxCardHeight, MinCardHeight),
          width: card_dragged.rec.width,
          height: card_dragged.rec.height,
        )
        # if let go of click -> remove click state
      elsif mouse_button_up?(0) && self.card_dragged
        card_dragged.rec = Rectangle.new(
          x: (self.card_offset[0] + mouse_x).clamp(MaxCardWidth, MinCardWidth),
          y: (self.card_offset[1] + mouse_y).clamp(MaxCardHeight, MinCardHeight),
          width: card_dragged.rec.width,
          height: card_dragged.rec.height,
        )
        Resolver.push [card_dragged]
        self.card_dragged.dragged = false
        self.card_dragged = false
        self.card_offset = false
      end
    end

    def check_overlap
      # check overlaps
      if !Resolver.empty?
        old_resolver = Resolver.flatten
        Resolver.clear
        old_resolver.each do |colliding_card|
          next if colliding_card.dragged
          Resolver.push []
          Card::Objects.each do |card|
            next if (card == colliding_card) || card.dragged
            if check_collision_recs(rec1: card.rec, rec2: colliding_card.rec)
              old_resolver.delete card
              Resolver.last.push colliding_card unless Resolver.last.include? colliding_card
              Resolver.last.push card
              recurse_check(card, old_resolver)
            end
          end
          Resolver.pop if Resolver.last.empty?
        end
      end
    end

    def recurse_check(colliding_card, old_resolver)
      Card::Objects.each do |card|
        next if (card == colliding_card) || card.dragged || (Resolver.last.include? card)
        if check_collision_recs(rec1: card.rec, rec2: colliding_card.rec)
          old_resolver.delete card
          Resolver.last.push colliding_card unless Resolver.last.include? colliding_card
          Resolver.last.push card
          recurse_check(card, old_resolver)
        end
      end
    end

    def resolve_overlap
      if !Resolver.empty?
        Resolver.each do |segment|
          center = [0.0, 0.0]
          segment.each do |card|
            # get center point
            center[0] += card.rec.x
            center[1] += card.rec.y
          end
          center[0] /= segment.length
          center[1] /= segment.length
          segment.each do |card|
            # move from center
            # direction
            dir = [card.rec.x - center[0], card.rec.y - center[1]]

            # Check to prevent NaN
            unless dir[0] == 0.0 && dir[1] == 0.0
              dir[0] = dir[0] / Math.sqrt((dir[0] ** 2) + (dir[1] ** 2))
              dir[1] = dir[1] / Math.sqrt((dir[0] ** 2) + (dir[1] ** 2))
            end

            # Smoothens out the movement
            card.momentum[0] += dir[0]
            card.momentum[1] += dir[1]
            card.momentum[0] /= SmoothenSteps.to_f
            card.momentum[1] /= SmoothenSteps.to_f

            dest = [
              (card.rec.x + card.momentum[0]).clamp(MaxCardWidth, MinCardWidth),
              (card.rec.y + card.momentum[1]).clamp(MaxCardHeight, MinCardHeight),
            ]

            card.rec = Rectangle.new(
              x: dest[0],
              y: dest[1],
              width: card.rec.width,
              height: card.rec.height,
            )
          end
        end
      end
    end

    def draw
      Card::Objects.each do |card|
        draw_rectangle_pro(rec: card.rec, origin: DefaultOrigin, rotation: 0, color: card.color)
        draw_rectangle_lines_ex(rec: card.rec, line_thick: 2, color: BLACK)
        draw_text(text: card.text, pos_x: card.rec.x + 7, pos_y: card.rec.y + 7, font_size: 30, color: BLACK)
      end
    end
  end
end

ColorRange = (0..255).to_a

CardNames = ('A'..'ZZ').to_a.reverse

15.times do
  Card.new(text: CardNames.pop, color: Color.new(r: ColorRange.sample, g: ColorRange.sample, b: ColorRange.sample, a: 255))
end

while !window_should_close do
  begin_drawing

  clear_background(WHITE)

  draw_rectangle_lines_ex(rec: BorderRec, line_thick: 5, color: BLACK)

  SmoothenSteps.times do
    Card.resolve_drag
    Card.check_overlap
    Card.resolve_overlap
  end
  Card.draw

  draw_fps(pos_x: 10, pos_y: 10)

  end_drawing
end
close_window
