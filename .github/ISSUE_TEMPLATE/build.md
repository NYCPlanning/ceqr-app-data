---
title: 
assignees: jpiacentinidcp, ileoyu, omarortiz1
labels: publish
---

A fresh run of ${{ github.event.inputs.dataset }} is complete! 🎉

## Staging files output:
- [ ] [version.txt](https://nyc3.digitaloceanspaces.com/edm-publishing/ceqr-app-data-staging/${{ github.event.inputs.dataset }}/latest/version.txt)
- [ ] [${{ github.event.inputs.dataset }}.zip](https://nyc3.digitaloceanspaces.com/edm-publishing/ceqr-app-data-staging/${{ github.event.inputs.dataset }}/latest/${{ github.event.inputs.dataset }}.zip)
- [ ] [${{ github.event.inputs.dataset }}.csv](https://nyc3.digitaloceanspaces.com/edm-publishing/ceqr-app-data-staging/${{ github.event.inputs.dataset }}/latest/${{ github.event.inputs.dataset }}.csv)

## Next Steps: 
If you have manually checked above files and they seem to be ok, comment `[publish]` under this issue. 
This would allow github actions to move staging files to production. 
Feel free to close this issue once it's all complete. Thanks!