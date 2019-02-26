class String

  #文字列がJANコードかの判定
  def jan?
    if self.length > 1 then
      judge = self[0, 2]
      if (judge == "45" || judge == "49") && (self.length == 13) then
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

  #文字列からJANコードを抽出
  def jan
    buf45 = /45\d{11}/.match(self)
    buf49 = /49\d{11}/.match(self)
    p buf45
    p buf49
    if buf45 != nil then
      return buf45[0]
    elsif buf49 != nil then
      return buf49[0]
    else
      return nil
    end
  end


end
