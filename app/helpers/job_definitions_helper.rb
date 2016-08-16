module JobDefinitionsHelper
  def distance_of_time(from, to)
    return '' if from.nil? || to.nil?

    secs  = (to - from).to_i
    mins  = secs / 60
    hours = mins / 60
    days  = hours / 24

    text = "%02d:%02d:%02d" % [hours % 24, mins % 60, secs % 60]
    text.prepend("#{days}days ") if days > 0
    text
  end
end
