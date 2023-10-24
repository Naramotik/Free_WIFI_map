package com.example.demo;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@CrossOrigin(origins = "http://localhost:3000")
@RequestMapping("/comment")
public class CommentController {
    @Autowired
    CommentRepository commentRepository;
    @Autowired
    MarkRepository markRepository;

    @PostMapping
    public HttpStatus createComment(@RequestBody CommentToPost commentToPost){
        System.out.println(commentToPost);
        Optional<Mark> mark = markRepository.findByLatitude(commentToPost.latitude);
        Comment comment = new Comment(null, commentToPost.getComment(), mark.get());
        commentRepository.save(comment);
        return HttpStatus.CREATED;
    }
    @GetMapping("/{latitude}")
    public ResponseEntity<List<Comment>> getComments(@PathVariable("latitude") String latitude){
        System.out.println(latitude);
        Optional<Mark> mark = markRepository.findByLatitude(latitude);
        return new ResponseEntity<List<Comment>> (commentRepository.findByMark(mark.get()), HttpStatus.OK);
    }
}
