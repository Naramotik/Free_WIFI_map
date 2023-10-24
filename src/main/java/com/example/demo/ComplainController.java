package com.example.demo;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Optional;

@RestController
@RequestMapping("/complain")
public class ComplainController {
    @Autowired
    ComplainRepository complainRepository;
    @Autowired
    MarkRepository markRepository;

    @PostMapping
    public HttpStatus createComplain(@RequestBody ComplainToPost complainToPost){
        System.out.println(complainToPost);
        Optional<Mark> mark = markRepository.findByLatitude(complainToPost.latitude);
        Complain complain  = new Complain(null, complainToPost.getComplain(), mark.get());
        complainRepository.save(complain);
        return HttpStatus.CREATED;
    }
}
