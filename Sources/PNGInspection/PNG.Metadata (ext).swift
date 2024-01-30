import PNG

extension PNG.Metadata:CustomStringConvertible
{
    public
    var description:String
    {
        [
            // singletons
            [
                self.time.map               (\.description),
                self.chromaticity.map       (\.description),
                self.colorProfile.map       (\.description),
                self.colorRendering.map     (\.description),
                self.gamma.map              (\.description),
                self.histogram.map          (\.description),
                self.physicalDimensions.map (\.description),
                self.significantBits.map    (\.description),
            ].compactMap{ $0 },
            self.suggestedPalettes.map      (\.description),
            self.text.map                   (\.description),
            self.application.map
            {
                """
                <unknown> (\($0.type))
                {
                    data        : <\($0.data.count) bytes>
                }
                """
            },
        ].flatMap{ $0 }.joined(separator: "\n")
    }
}
