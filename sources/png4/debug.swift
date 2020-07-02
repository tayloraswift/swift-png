extension PNG.Text:CustomStringConvertible 
{
    public 
    var description:String 
    {
        """
        png.text (tEXt | zTXt | iTXt) 
        {
            compressed  : \(self.compressed)
            language    : '\(self.language.joined(separator: "-"))'
            keyword     : '\(self.keyword.english)', '\(self.keyword.localized)'
            content     : \"\(self.content)\"
        }
        """
    }
}
