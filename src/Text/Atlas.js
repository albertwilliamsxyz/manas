// Loads the BMFont JSON metadata produced by msdf-bmfont-xml and flattens it
// into the shape PureScript expects. The original JSON nests scaleW/scaleH under
// `common` and distanceRange under `distanceField`; we project the fields we use
// at the top level so PureScript records map 1:1.
export const loadAtlasMetadataImpl = (url) => () => fetch(url)
    .then(response => {
        if (!response.ok) throw new Error("Failed to load atlas metadata: " + url);
        return response.json();
    })
    .then(data => ({
        scaleW: data.common.scaleW,
        scaleH: data.common.scaleH,
        lineHeight: data.common.lineHeight,
        distanceRange: data.distanceField.distanceRange,
        glyphs: data.chars.map(c => ({
            char: c.char,
            x: c.x,
            y: c.y,
            width: c.width,
            height: c.height,
            xoffset: c.xoffset,
            yoffset: c.yoffset,
            xadvance: c.xadvance
        }))
    }));
