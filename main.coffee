
# Credits to the JS code from Rafał Lindemann (http://panrafal.github.com/depthy)

parseCompound = (data)->
    extendedXmp = (data.match(/xmpNote:HasExtendedXMP="(.+?)"/i) || [])[1];
    if extendedXmp
        data = data.replace(new RegExp('[\\s\\S]{4}http:\\/\\/ns\\.adobe\\.com\\/xmp\\/extension\\/[\\s\\S]' + extendedXmp + '[\\s\\S]{8}', 'g'), '')
    xmp = data.match(/<x:xmpmeta [\s\S]+?<\/x:xmpmeta>/g)
    result = {}
    if (!xmp)
        throw "No XMP metadata found!"
    xmp = xmp.join("\n", xmp)
    result.imageMime = (xmp.match(/GImage:Mime="(.+?)"/i) || [])[1]
    result.imageData = (xmp.match(/GImage:Data="(.+?)"/i) || [])[1]
    result.depthMime = (xmp.match(/GDepth:Mime="(.+?)"/i) || [])[1]
    result.depthData = (xmp.match(/GDepth:Data="(.+?)"/i) || [])[1]
    if (result.imageMime && result.imageData)
        result.imageUri = 'data:' + result.imageMime + ';base64,' + result.imageData
    if (result.depthMime && result.depthData)
        result.depthUri = 'data:' + result.depthMime + ';base64,' + result.depthData
    if (!result.depthUri)
        throw "No depth map found!"
    if (!result.imageUri)
        throw "No original image found!"
    result.focalDistance = (xmp.match(/GFocus:FocalDistance="(.+?)"/i) || [])[1];
    result

handleFileSelect = (evt)->
    cb = ->
        files = evt.target.files
        file = files[0]
        imageReader = new FileReader()
        imageReader.onload = (e)->
            compound = parseCompound e.target.result
            canvas = document.getElementById 'wigglestereoscopy'
            load_animation compound.imageUri, compound.depthUri, canvas, (animation)->
                animation.play canvas, 50
        imageReader.readAsBinaryString file
    window.setTimeout cb,0




document.getElementById('files').addEventListener 'change', handleFileSelect, false
