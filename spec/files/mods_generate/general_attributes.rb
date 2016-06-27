module GeneralAttributes
  def updater
   super.present? ? super : "移行ツール"
  end

  def updated_at
    super.present? ? super : Time.now
  end
end
