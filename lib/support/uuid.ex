defmodule UUID do
  def generate do
    List.to_string( :uuid.to_string(:uuid.uuid4()))
  end
end