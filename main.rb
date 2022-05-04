include Test # temporary WiP name for raylib bindings


WHITE = Color.new(r: 255, g: 255, b: 255, a: 255)
BLACK = Color.new(r: 0, g: 0, b: 0, a: 255)
GRAY = Color.new(r: 100, g: 100, b: 100, a: 255)

screen_width = 800
screen_height = 450

init_window(width: screen_width, height: screen_height, title: "Card Example Thingie")
Test.target_fps = 60

DefaultOrigin = Vector2.new(x: 0, y: 0)

class Card
  # size of cards
  Width = 80
  Height = (Width * (4.0/3.0)).to_i

  # list of valid coordinates a card can spawn
  ValidSpawnRange = [(0..(800-Card::Width)).to_a, (0..(450-Card::Height)).to_a] 

  # stores any new cards that are created
  Objects = [] 

  # stores groups of cards that are overlapping
  Resolver = [] 

  attr_accessor :rec, :text, :color, :dragged

  def initialize(rec: Rectangle.new(x: ValidSpawnRange[0].sample, y: ValidSpawnRange[1].sample, width: Card::Width, height: Card::Height),
                 text: "New Card",
                 color: WHITE)
    self.rec = rec
    self.text = text
    self.color = color
    self.dragged = false
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
          #mouse_position # Vector2
          #mouse_delta # Vector2
          if check_collision_point_rec(point: mouse_position, rec: card.rec)
            self.card_dragged = card
            card.dragged = true
            self.card_offset = [card.rec.x - mouse_x, card.rec.y - mouse_y]

            # place card at front of array(to draw first)
            Card::Objects.push Card::Objects.delete(card)
            break
          end
        end
        # if holding click -> check which one is being clicked -> drag it
      elsif mouse_button_down?(0) && self.card_dragged
        card_dragged.rec = Rectangle.new(x: (self.card_offset[0] + mouse_x), y: (self.card_offset[1] + mouse_y), width: card_dragged.rec.width, height: card_dragged.rec.height)
        # if let go of click -> remove click state
      elsif mouse_button_up?(0) && self.card_dragged
        #card_dragged.rec.x = self.card_offset[0] + mouse_x
        #card_dragged.rec.y = self.card_offset[1] + mouse_y
        card_dragged.rec = Rectangle.new(x: (self.card_offset[0] + mouse_x), y: (self.card_offset[1] + mouse_y), width: card_dragged.rec.width, height: card_dragged.rec.height)
        self.card_dragged.dragged = false
        self.card_dragged = false
        self.card_offset = false
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

('A'..'E').each do |letter|
  Card.new(text: letter, color: Color.new(r: ColorRange.sample, g: ColorRange.sample, b: ColorRange.sample, a: 255))
end

while !window_should_close do
  begin_drawing

  clear_background(WHITE)

  Card.draw
  Card.resolve_drag

  #draw_text(text: "Congrats! You created your first window!", pos_x: 190, pos_y: 200, font_size: 20, color: GRAY)

  end_drawing
end
close_window
