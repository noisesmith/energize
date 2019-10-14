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

(fn any-inside? [x y size img-data]
  (or (inside-img? x y img-data)
      (inside-img? (+ x size -1) y img-data)
      (inside-img? x (+ y size -1) img-data)
      (inside-img? (+ x size -1) (+ y size -1) img-data)
      ;; checking the corners isn't good enough; need to
      ;; recurse down to a minimum granularity
      (and (> size 4) (any-inside? x y (/ size 2) img-data))))

(fn chunks-for [img-data field]
  (print :new)
  (let [chunks []]
    (for [x 0 field.w size]
      (for [y 0 field.h size]
        (when (any-inside? x y size img-data)
          (table.insert chunks {:x (+ x field.ox)
                                :y (+ y field.oy)
                                :w size :h size
                                :id (.. x "x" y)}))))
    chunks))

{:find find :for chunks-for}
