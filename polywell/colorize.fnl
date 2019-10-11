;; Private module; do not load this directly!
(local lume (require :polywell.lib.lume))

(fn keyword-color [keyword colors]
  (if (= :string (type keyword))
      [keyword colors.keyword]
      [(. keyword 1) (. colors (. keyword 2)) (. keyword 3)]))

(fn colorize-keyword [keywords colors l n offset]
  (if (and n (> n (# keywords)))
      [colors.text l]
      (let [[keyword color fancy?] (keyword-color (. keywords (or n 1)) colors)
            (s e) (string.find l keyword offset (not fancy?))]
        (if (and s (or (string.find (string.sub l (- s 1) (- s 1)) "[%w_]")
                       (and e (string.find (string.sub l (+ e 1) (+ e 1))
                                           "[%w_]"))))
            (colorize-keyword keywords colors l n (+ e 1))
            (= s 1)
            [color (string.sub l 1 e)
             (unpack (colorize-keyword keywords colors (string.sub l (+ e 1))))]
            s
            (let [pre (colorize-keyword keywords colors
                                        (string.sub l 1 (- s 1)))]
              (lume.concat pre [color (string.sub l s e)
                                (unpack (colorize-keyword keywords colors
                                                          (string.sub l (+ e 1))))]))
            ;; else
            (colorize-keyword keywords colors l (+ (or n 1) 1))))))

(fn colorize-number [keywords colors l offset]
  (let [(s e) (string.find l "[\\.0-9]+" offset)]
    (if (and s (string.find (string.sub l (- s 1) (- s 1)) "[%w_]"))
        (colorize-number keywords colors l (+ e 1))
        (= s 1)
        [colors.number (string.sub l 1 e)
         (unpack (colorize-number keywords colors (string.sub l (+ e 1))))]
        s
        (let [line (colorize-keyword keywords colors (string.sub l 1 (- s 1)))]
          (lume.concat line [colors.number (string.sub l s e)
                             (unpack (colorize-number keywords colors
                                                      (string.sub l (+ e 1))))]))
        ;; else
        (colorize-keyword keywords colors l))))

(var comment-match nil)

(fn colorize-comment [keywords colors l]
  (set comment-match (and keywords.comment_pattern
                          (string.find l keywords.comment_pattern)))
  (if (= comment-match 1)
      [colors.comment l]
      comment-match
      (let [n (string.sub l 1 (- comment-match 1))
            line (colorize-number keywords colors n)]
        (table.insert line colors.comment)
        (table.insert line (string.sub l comment-match))
        line)
      ;; else
      (colorize-number keywords colors l)))

(fn colorize-string [keywords colors l]
  (let [(s e) (string.find l "\"[^\"]*\"")]
    (if (= s 1)
        [colors.str (string.sub l 1 e)
         (unpack (colorize-comment keywords colors (string.sub l (+ e 1))))]
        s
        (let [pre (colorize-comment keywords colors (string.sub l 1 (- s 1)))]
          (if comment-match
              (do (table.insert pre colors.comment)
                  (table.insert pre (string.sub l s))
                  pre)
              (let [post (colorize-string keywords colors
                                          (string.sub l (+ e 1)))]
                (lume.concat pre [colors.str (string.sub l s e)] post))))
        ;; else
        (colorize-comment keywords colors l))))

(fn colorize [keywords colors lines]
  (lume.map lines (lume.fn colorize-string keywords colors)))
