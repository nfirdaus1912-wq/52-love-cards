# Card schema

`packs.json` on S3 (and the bundled fallback) uses this shape.

```json
{
  "version": 1,
  "packs": [
    {
      "id": "couple",
      "name": "Couple",
      "cards": [
        {
          "id": "couple-1",
          "text": "Question shown on the single card chrome.",
          "mood": "romantic",
          "roundType": "know_me",
          "intensity": "light"
        }
      ]
    }
  ]
}
```

- `blurb`: optional short line on the pack tile
- `mood`: `romantic` | `challenge`
- `roundType`: `know_me` | `your_turn`
- `intensity`: `light` | `medium` | `spicy`
- No images. One UI card theme; only `text` changes.

Draw: Romantic → `know_me`. Challenge → `your_turn`. Mix → 4 + 4. Session length 8 when subscribed. Free: one romantic card.
