(local lume (require :polywell.lib.lume))
(local size 24)

(fn in-bounds? [x y img field])

(fn hit? [x y chunk]
  (and (<= chunk.x x (+ chunk.x chunk.w))
       (<= chunk.y y (+ chunk.y chunk.h))))

(fn inside-img? [x y img-data]
  (let [(mx my) (img-data:getDimensions)]
    (let [(r g b a) (if (and (< x mx) (< y my))
                        (img-data:getPixel x y))]
      (= a 1))))

(fn find [field {: x : y} img-data chunks]
  (let [relx (- x field.ox)
        rely (- y field.oy)]
    (and (inside-img? relx rely img-data)
         (lume.match chunks (partial hit? x y)))))

(fn chunks-for [img-data field]
  (let [chunks []]
    (for [y 0 field.h size]
      (for [x 0 field.w size]
        (when (or (inside-img? x y img-data)
                  (inside-img? (+ x size) y img-data)
                  (inside-img? x (+ y size) img-data)
                  (inside-img? (+ x size) (+ y size) img-data))
          (table.insert chunks {:x (+ x field.ox)
                                :y (+ y field.oy)
                                :w size :h size
                                :id (.. x "x" y)}))))
    chunks))

{:find find :for chunks-for}
