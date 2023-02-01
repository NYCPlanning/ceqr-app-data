---
title: [publish] {{ env.DATASET }}
assignees: jpiacentinidcp, ileoyu, omarortiz1, rtblair
---

A fresh run of {{ env.DATASET }} is complete! 🎉

## Staging files output:
- [ ] [version.txt](https://nyc3.digitaloceanspaces.com/edm-publishing/ceqr-app-data-staging/{{ env.DATASET }}/latest/version.txt)
- [ ] [{{ env.DATASET }}.zip](https://nyc3.digitaloceanspaces.com/edm-publishing/ceqr-app-data-staging/{{ env.DATASET }}/latest/{{ env.DATASET }}.zip)
- [ ] [{{ env.DATASET }}.csv](https://nyc3.digitaloceanspaces.com/edm-publishing/ceqr-app-data-staging/{{ env.DATASET }}/latest/{{ env.DATASET }}.csv)

## Next Steps: 
If you have manually checked above files and they seem to be ok, comment `[publish]` under this issue. 
This would allow github actions to move staging files to production. 
Feel free to close this issue once it's all complete. Thanks!
