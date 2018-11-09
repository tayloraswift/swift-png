import PNG

enum Group
{
    case mapStrings(_ expectation:Bool, _ name:String, _ function:(String) -> String?, [String]),
         functions(_ expectation:Bool, _ name:String, _ functions:[(name:String, function:() -> String?)])

    var count:Int
    {
        switch self
        {
            case .mapStrings(_, _, _, let cases):
                return cases.count

            case .functions(_, _, let functions):
                return functions.count
        }
    }

    var name:String
    {
        switch self
        {
            case .mapStrings(_, let name, _, _):
                return name
            case .functions(_, let name, _):
                return name
        }
    }

    func forEach(filter:Set<String>? = nil, body:(String, Bool, String?) -> ())
    {
        switch self
        {
            case .mapStrings(let expectation, _, let function, let cases):
                (
                    filter.map
                    {
                        (filter:Set<String>) in
                        cases.filter
                        {
                            filter.contains("\(self.name):\($0)")
                        }
                    }
                    ??
                    cases
                ).forEach
                {
                    body($0, expectation, function($0))
                }

            case .functions(let expectation, _, let functions):
                for (string, function):(String, () -> String?) in functions
                {
                    if let filter:Set<String> = filter
                    {
                        guard filter.contains("\(self.name):\(string)")
                        else
                        {
                            return
                        }
                    }

                    body(string, expectation, function())
                }
        }
    }
}

let suite:[(name:String, members:[String])] =
[
    (
        "basic",
        [
            "PngSuite",

            "basn0g01",
            "basn0g02",
            "basn0g04",
            "basn0g08",
            "basn0g16",
            "basn2c08",
            "basn2c16",
            "basn3p01",
            "basn3p02",
            "basn3p04",
            "basn3p08",
            "basn4a08",
            "basn4a16",
            "basn6a08",
            "basn6a16"
        ]
    ),
    (
        "interlacing",
        [
            "basi0g01",
            "basi0g02",
            "basi0g04",
            "basi0g08",
            "basi0g16",
            "basi2c08",
            "basi2c16",
            "basi3p01",
            "basi3p02",
            "basi3p04",
            "basi3p08",
            "basi4a08",
            "basi4a16",
            "basi6a08",
            "basi6a16"
        ]
    ),
    (
        "sizing",
        [
            "s01i3p01",
            "s01n3p01",
            "s02i3p01",
            "s02n3p01",
            "s03i3p01",
            "s03n3p01",
            "s04i3p01",
            "s04n3p01",
            "s05i3p02",
            "s05n3p02",
            "s06i3p02",
            "s06n3p02",
            "s07i3p02",
            "s07n3p02",
            "s08i3p02",
            "s08n3p02",
            "s09i3p02",
            "s09n3p02",
            "s32i3p04",
            "s32n3p04",
            "s33i3p04",
            "s33n3p04",
            "s34i3p04",
            "s34n3p04",
            "s35i3p04",
            "s35n3p04",
            "s36i3p04",
            "s36n3p04",
            "s37i3p04",
            "s37n3p04",
            "s38i3p04",
            "s38n3p04",
            "s39i3p04",
            "s39n3p04",
            "s40i3p04",
            "s40n3p04"
        ]
    ),
    (
        "backgrounds",
        [
            "bgai4a08",
            "bgai4a16",
            "bgan6a08",
            "bgan6a16",
            "bgbn4a08",
            "bggn4a16",
            "bgwn6a08",
            "bgyn6a16"
        ]
    ),
    (
        "transparency",
        [
            "tbbn0g04",
            "tbbn2c16",
            "tbbn3p08",
            "tbgn2c16",
            "tbgn3p08",
            "tbrn2c08",
            "tbwn0g16",
            "tbwn3p08",
            "tbyn3p08",
            "tm3n3p02",
            "tp0n0g08",
            "tp0n2c08",
            "tp0n3p08",
            "tp1n3p08"
        ]
    ),
    (
        "(inactive)",
        [
            "g03n0g16",
            "g03n2c08",
            "g03n3p04",
            "g04n0g16",
            "g04n2c08",
            "g04n3p04",
            "g05n0g16",
            "g05n2c08",
            "g05n3p04",
            "g07n0g16",
            "g07n2c08",
            "g07n3p04",
            "g10n0g16",
            "g10n2c08",
            "g10n3p04",
            "g25n0g16",
            "g25n2c08",
            "g25n3p04"
        ]
    ),
    (
        "filtering",
        [
            "f00n0g08",
            "f00n2c08",
            "f01n0g08",
            "f01n2c08",
            "f02n0g08",
            "f02n2c08",
            "f03n0g08",
            "f03n2c08",
            "f04n0g08",
            "f04n2c08",
            "f99n0g04"
        ]
    ),
    (
        "palettes",
        [
            "pp0n2c16",
            "pp0n6a08",
            "ps1n0g08",
            "ps1n2c16",
            "ps2n0g08",
            "ps2n2c16"
        ]
    ),
    (
        "ancillary chunks",
        [
            "ccwn2c08",
            "ccwn3p08",
            "cdfn2c08",
            "cdhn2c08",
            "cdsn2c08",
            "cdun2c08",
            "ch1n3p04",
            "ch2n3p08",
            "cm0n0g04",
            "cm7n0g04",
            "cm9n0g04",
            "cs3n2c16",
            "cs3n3p08",
            "cs5n2c08",
            "cs5n3p08",
            "cs8n2c08",
            "cs8n3p08",
            "ct0n0g04",
            "ct1n0g04",
            "cten0g04",
            "ctfn0g04",
            "ctgn0g04",
            "cthn0g04",
            "ctjn0g04",
            "ctzn0g04"
        ]
    ),
    (
        "ordering",
        [
            "oi1n0g16",
            "oi1n2c16",
            "oi2n0g16",
            "oi2n2c16",
            "oi4n0g16",
            "oi4n2c16",
            "oi9n0g16",
            "oi9n2c16"
        ]
    ),
    (
        "zlib compression",
        [
            "z00n2c08",
            "z03n2c08",
            "z06n2c08",
            "z09n2c08"
        ]
    ),
    (
        "large",
        [
            "becky palette",
            "if red got the grammy",
            "taylor",
            "wildest dreams adam7"
        ]
    ),
]
let cases:[Group] =
[
    .functions(true, "rgba operations",
        [
            (
                "premultiply8",
                {
                    testPremultiplication(for: UInt8.self)
                }
            ),
            // this takes way too long to run
            /* (
                "premultiply16",
                {
                    testPremultiplication(for: UInt16.self)
                }
            ) */
        ]
    )
]
+
suite.map
{
    .mapStrings(true, $0.name + "-decode", testDecode(_:), $0.members)
}
+
suite.map
{
    .mapStrings(true, $0.name + "-reencode", testEncode(_:), $0.members)
}
