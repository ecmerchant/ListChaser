class String
  def jan?
    if self.length > 1 then
      judge = self[0, 2]
      if (judge == "45" || judge == "49") && (self.length == 13 || self.length == 8) then
        p "YES, JAN!!"
        return true
      else
        p "OH, NO JAN.."
        return false
      end
    else
      return false
    end
  end
end
