load_image_data = (path, callback)->
    # load an image and returns its
    # "data".
    img = new Image()
    img.src = path
    img.onload = ->
        W = img.width
        H = img.height
        canvas = document.createElement 'canvas'
        canvas.width = W
        canvas.height = H
        ctx = canvas.getContext '2d'
        ctx.drawImage img,0,0,W,H
        img_data = ctx.createImageData W,H
        callback ctx.getImageData 0,0,W,H

create_image_data = (W,H)->
    canvas = document.createElement 'canvas'
    ctx = canvas.getContext '2d'
    ctx.createImageData W,H

fill_with_average = (data, W, H)->
    # Detect black pixels and fill then with
    # their neighbors average.
    N = W*H*4
    for c in [0...N] by 4
        if data[c + 3] == 0
            # we have a black pixel here
            neighbor_count = 0
            [r,g,b] = [0,0,0]
            for neighbor in [-W*4,W*4,-4,4]
                neighbor_offset = c+neighbor
                if 0 <= neighbor_offset < N
                    if data[neighbor_offset + 3] > 0
                        neighbor_count += 1
                        r += data[neighbor_offset+0]
                        g += data[neighbor_offset+1]
                        b += data[neighbor_offset+2]
            if neighbor_count>0
                data[c] = Math.ceil(r/neighbor_count)
                data[c+1] = Math.ceil(g/neighbor_count)
                data[c+2] = Math.ceil(b/neighbor_count)
                if neighbor_count > 1
                    # if there is 2 or more
                    # neighbor, we allow
                    # the new value for the pixel to 
                    # be used for its own neighbors.
                    data[c+3] = 255

render_scene = (img, depth, camera)->
    # the poor man's 3d
    W = img.width 
    H = img.height
    dest = create_image_data W,H
    imgp = img.data
    depthp = depth.data
    destp = dest.data
    x0 = Math.ceil (W/2)
    y0 = Math.ceil (H/2)
    d0 = depthp[ (x0+W*y0)*4 ]
    c = 0
    N = W*H*4
    for j in [0...H]
        for i in [0...W] 
            d = (depthp[c]-d0)
            r = camera.L  / (camera.L - d)
            # compute x,y : the projection of pixel (i,j,d)
            # according to our camera.
            x = Math.floor(x0 - camera.x + (camera.x + i - x0) * r) 
            y = Math.floor(y0 - camera.y + (camera.y + j - y0) * r)
            destc = (x+W*y)*4
            if (0 <= destc < N)
                for v in [0..3]
                    destp[destc+v] = imgp[c+v]
            c+=4
    fill_with_average destp, W, H
    for c in [0...W*H*4] by 4
        destp[c+3] = 255
    return dest


class Animation
    ###
    Just a small class hosting frames
    ###
    constructor: (@frames)->
        if @frames.length == 0
            throw "Your animation requires at least one frame."

    play: (canvas,speed=12)->
        # speed is in frame per second
        @stop()
        ctx = canvas.getContext '2d'
        frame_id = 0
        canvas.width = @width()
        canvas.height = @height()
        render_frame = =>
            frame_id = (frame_id + 1) % @frames.length
            ctx.putImageData @frames[frame_id], 0, 0    
        @timer = setInterval render_frame, 1000.0/speed

    stop: ->
        if @timer?
            clearInterval @timer
            @timer = null

    height: ->
        @frames[0].height

    width: ->
        @frames[0].width


camera_from_angle = (h, theta)->
        x: Math.cos(theta)*h
        y: Math.sin(theta)*h
        L: 2000

compute_animation = (img, depth, cameras)->
    new Animation( render_scene(img,depth,camera) for camera in cameras )

load_animation = (animation_id, canvas, callback)->
    nb_frames = 12    
    h = 60.0
    thetas = ( Math.PI*2.0*i/nb_frames for i in [0...nb_frames] )
    cameras = ( camera_from_angle(h,theta) for theta in thetas )
    load_image_data (animation_id + '.png'), (img)->
        load_image_data (animation_id + '_depth.png'), (depth)->
            callback compute_animation(img, depth, cameras)

# stuff we want to export
@load_animation = load_animation
@compute_animation = compute_animation
@Animation =Animation
