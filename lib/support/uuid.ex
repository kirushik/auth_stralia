defmodule UUID do
  def generate do
    list_to_bitstring( :uuid.to_string(:uuid.uuid4()))
  end
end