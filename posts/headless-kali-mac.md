# Headless Kali on a Mac: How I Stopped Carrying Two Laptops

I happen to have two laptops. My primary is a MacBook Air M4, which I love for all its greatness except storage. That one limitation creates other limitations too, like the lack of dynamic swap and the inability to comfortably run VMs. My other device is a few-years-old Lenovo IdeaPad 5 (i5 12th gen, Iris Xe). It came with Windows, but like any adventurous dev I set up a Linux dual boot on it, and I bowed down to Kali. It's a bit bloated and full of tools I'm yet to learn how to use, but to swim you need to be in the water.

I sometimes need Kali exclusively, and on some days I need my Mac. I'm a strong guy with a big backpack, but carrying two laptops is no fun, so I was frustrated. I knew I could keep Kali at home and SSH into it, but sometimes you just need a GUI. It's convenient. So for a few months I had two options: pick one laptop, or put myself through the agony of carrying both.

A few weeks ago, a friend (who uses Arch, btw) introduced me to OpenCode. I had two problems: (A) I had issues setting it up on my Mac, and (B) my work required OpenCode to run for a prolonged duration, and I knew the best place to set it up was Linux. So I did.

While OpenCode was doing its work, I needed to keep a constant watch on it. Since I was home for those few days, it wasn't an issue; I'd keep the laptop next to me while using the Mac. But then I had to be away from home for college, and I couldn't leave OpenCode unsupervised. I also couldn't run it on the Mac: it would eat my resources, need constant internet access, and I'd have to let the Mac keep running with the lid closed. On top of that I'd have to set everything up again, so it was a no-go.

As they say, "Necessity is the mother of invention." In my case it was more of a discovery, in all honesty. I was already familiar with concepts like AnyDesk, TeamViewer and Remote Desktop (that last one especially thanks to *Scammer Payback*). So, like many modern curious devs in circa 2026, I went to my AI, explained my problems and what I needed to achieve, and it was a great help and amplified my abilities. It taught me about **Tailscale** and **XRDP**, two things I didn't know about before. *[Achievement Unlocked x2: Discover Tailscale & XRDP]*

And thus began my journey. First of all, installing Tailscale on the Mac was itself an obstacle I had to cross. Later, setting up IPs and so on was something I had learnt in some capacity in my Cloud Computing class during my AWS and Google Cloud courses. But, to be honest, this was my first time doing it on real hardware, on my own, without instructions. I know where I wish to go, but I'm blazing my own trail.

I have documented this whole thing in extensive detail in my GitHub repo, **headless-kali-mac**: <https://github.com/beeth73/headless-kali-mac>. Do check it out.

This entry is more about my journey, so treat it like a travelogue. And for all my mates who want the TL;DR of what the project is, let's dive in.


![Headless Kali Linux Desktop on macOS](https://raw.githubusercontent.com/beeth73/headless-kali-mac/main/docs/images/hero-desktop.png)

*Figure: Kali Linux (XFCE) running headless over an SSH-tunneled WireGuard mesh. Source: [beeth73/headless-kali-mac on GitHub](https://github.com/beeth73/headless-kali-mac)*

---

## The Setup

My Kali machine (the Lenovo) is parked at home, connected to Wi-Fi and power, the two resources it needs to run. My Mac is with me, and it's connected to my home Wi-Fi, college Wi-Fi, or my phone's hotspot, so it always has a different IP (Internet Protocol address). My Kali machine doesn't have a static IP either, because standard home broadband connections typically use dynamic IPs and sit behind Carrier-Grade NAT (CG-NAT), which doesn't support direct port forwarding.

This is a problem we need to solve. SSH needs one device to be able to reach the other at a known address, and behind CG-NAT nothing from the outside can reach my Kali machine. You *could* allow `0.0.0.0/0`, and congrats, now the whole world is welcome, so good luck kicking out uninvited guests!

This setup achieves the exact opposite of exposing everything to 0.0.0.0/0: we have zero open ports to the internet. XRDP isn't even exposed to my home router or the open web. It's locked down to local loopback (127.0.0.1), accessible only through an authenticated SSH tunnel riding on our private Tailscale mesh. Shodan and internet port scanners see absolute silence.

To bridge the gap securely, I forwarded Kali's internal RDP port to my Mac's local loopback over an SSH tunnel (ssh -L 33389:localhost:3389). So in the Windows App, I simply point to 127.0.0.1:33389.

## The Detour: VPNs

So how did I solve this? Let's look at how a VPN works first:

1. Your device has an ever-changing dynamic IP.
2. The VPN provider has a static IP.
3. Your device tells the VPN provider "I'm here, and this is me," and then reroutes all your network packets through the provider, thus taking on their IP and geolocation.

By this time, in some capacity, we all know how VPNs work. But how does that relate to my work? As established, SSH needs reachable addresses, and CG-NAT doesn't allow port forwarding, so we still have two problems to resolve.

## Drum Roll Please: Tailscale

So what does Tailscale do, and how? It gives each of my devices a stable private IP (call them IP-a for the Mac and IP-b for Kali) that stays the same no matter which network they're on. Traffic between them travels over encrypted WireGuard tunnels using UDP. And because both devices reach out to coordinate with Tailscale, they can perform NAT traversal (hole punching) to connect directly, bypassing the CG-NAT limitation. You've not only resolved the major problems but also laid the foundation for your project.

![Tailscale Direct Peer-to-Peer Connection Status](https://raw.githubusercontent.com/beeth73/headless-kali-mac/main/docs/images/tailscale-status.png)

*Figure: Tailscale telemetry demonstrating a direct peer-to-peer WireGuard link across NAT gateways with 9 ms latency. Source: [beeth73/headless-kali-mac on GitHub](https://github.com/beeth73/headless-kali-mac)*

## The GUI Part

It doesn't end just yet, though. For GUI control on the Mac, I use the **Windows App** (yes, it's made by Microsoft; it's Remote Desktop, but they renamed it on Mac), and on Kali you need **XRDP**.

![Windows App Remote Desktop Configuration](https://raw.githubusercontent.com/beeth73/headless-kali-mac/main/docs/images/windows-app-config.png)

*Figure: Windows App setup on macOS routing to the local SSH-forwarded loopback socket (`127.0.0.1:33389`). Source: [beeth73/headless-kali-mac on GitHub](https://github.com/beeth73/headless-kali-mac)*

To all my GNOME lovers: sadly, I wasn't able to get it working on GNOME and had to resort to Xfce. To all my Xfce lovers: it's a solid desktop environment, honestly. Not as pretty as GNOME, but it works perfectly.

## Parking the Lenovo

As I was parking my Lenovo, I had to change config files in Kali so it could run uninterrupted with the lid closed. After setting up everything, voila, it worked perfectly for over a week. And no, it didn't fail afterwards; I just had to use Windows on it, so I stopped the setup. That whole debacle is documented here in the **DEADLOCK_POST_MORTEM**: <https://github.com/beeth73/headless-kali-mac/blob/main/DEADLOCK_POST_MORTEM.md>. Do give it a read. I learnt a lot while closing it out too, which I didn't expect at all.


```bash
# In /etc/systemd/logind.conf:
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
```


And the nuclear option to make sure the kernel never sleeps, even if firmware tries to force it:

```bash
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
sudo systemctl restart systemd-logind
```

Once this was done I was able to close the lid while laptop was still working!

---

## Conclusion

To conclude, I learnt a lot about computer networks, operating systems, and, can we call it cloud computing if I'm the one hosting the server? If you had asked me a few weeks ago, I'm sure I wouldn't have had this much depth of understanding on this topic, which I have now achieved by doing it myself. In Hour 1 I was having trouble just installing Tailscale on the Mac, and in the last hour I was closing out Kali. We are all capable of great things; we must take that **leap of faith**!

***May the Force be with us all!***